import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { v4 as uuidv4 } from 'uuid';
import { z } from 'zod';
import { verifyToken } from '../middleware/auth.js';
import { createPost, getPostsByUser, getFeedPosts } from '../repositories/postRepository.js';
import { getUser } from '../repositories/userRepository.js';
import {
  created,
  ok,
  unauthorized,
  forbidden,
  notFound,
  validationError,
  internalError,
} from '../utils/response.js';

const CreatePostSchema = z.object({
  mispronounced: z
    .string()
    .min(1, '言い間違った言葉を入力してください')
    .max(100, '言い間違った言葉は100文字以内で入力してください'),
  intended: z
    .string()
    .min(1, '伝えたかった言葉を入力してください')
    .max(100, '伝えたかった言葉は100文字以内で入力してください'),
  description: z
    .string()
    .max(500, '説明は500文字以内で入力してください')
    .optional(),
});

function encodeNextToken(key: Record<string, unknown>): string {
  return Buffer.from(JSON.stringify(key)).toString('base64url');
}

function decodeNextToken(token: string): Record<string, unknown> | undefined {
  try {
    return JSON.parse(Buffer.from(token, 'base64url').toString()) as Record<string, unknown>;
  } catch {
    return undefined;
  }
}

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const userId = await verifyToken(event);
    if (!userId) return unauthorized();

    const method = event.httpMethod;
    const path = event.path;
    const query = event.queryStringParameters ?? {};

    const limit = Math.min(Number(query['limit'] ?? 20), 50);
    const nextToken = query['nextToken'];
    const startKey = nextToken ? decodeNextToken(nextToken) : undefined;

    // POST /posts
    if (method === 'POST' && /\/posts\/?$/.test(path)) {
      const user = await getUser(userId);
      if (!user) {
        return forbidden('ニックネームを設定してから投稿してください');
      }

      const body = JSON.parse(event.body ?? '{}');
      const parsed = CreatePostSchema.safeParse(body);
      if (!parsed.success) {
        return validationError(parsed.error.errors[0]?.message ?? 'バリデーションエラー');
      }

      const post = {
        postId: uuidv4(),
        userId,
        mispronounced: parsed.data.mispronounced,
        intended: parsed.data.intended,
        description: parsed.data.description,
        createdAt: new Date().toISOString(),
        feedPartition: 'ALL' as const,
      };
      await createPost(post);
      return created(post);
    }

    // GET /posts/me
    if (method === 'GET' && path.endsWith('/posts/me')) {
      const { posts, lastEvaluatedKey } = await getPostsByUser(userId, limit, startKey);
      const user = await getUser(userId);
      const nickname = user?.nickname ?? '';
      return ok({
        posts: posts.map((p) => ({ ...p, nickname })),
        nextToken: lastEvaluatedKey ? encodeNextToken(lastEvaluatedKey) : undefined,
      });
    }

    // GET /posts
    if (method === 'GET' && /\/posts\/?$/.test(path)) {
      const { posts, lastEvaluatedKey } = await getFeedPosts(limit, startKey);
      // ニックネームをユーザテーブルから取得（ユニークユーザIDごとにバッチ取得）
      const userIds = [...new Set(posts.map((p) => p.userId))];
      const users = await Promise.all(userIds.map((id) => getUser(id)));
      const nicknameMap = new Map(
        users.filter(Boolean).map((u) => [u!.userId, u!.nickname])
      );
      return ok({
        posts: posts.map((p) => ({ ...p, nickname: nicknameMap.get(p.userId) ?? '' })),
        nextToken: lastEvaluatedKey ? encodeNextToken(lastEvaluatedKey) : undefined,
      });
    }

    return notFound();
  } catch (err) {
    console.error('posts handler error:', err);
    return internalError();
  }
};
