import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { z } from 'zod';
import { verifyToken } from '../middleware/auth.js';
import { getUser, putUser } from '../repositories/userRepository.js';
import {
  ok,
  notFound,
  unauthorized,
  validationError,
  internalError,
} from '../utils/response.js';

const UpdateProfileSchema = z.object({
  nickname: z
    .string()
    .min(1, 'nicknameは1文字以上で入力してください')
    .max(20, 'nicknameは20文字以内で入力してください'),
});

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const userId = await verifyToken(event);
    if (!userId) return unauthorized();

    const method = event.httpMethod;
    const path = event.path;

    if (method === 'GET' && path.endsWith('/users/me')) {
      const user = await getUser(userId);
      if (!user) return notFound('ユーザが存在しません');
      return ok(user);
    }

    if (method === 'PUT' && path.endsWith('/users/me')) {
      const body = JSON.parse(event.body ?? '{}');
      const parsed = UpdateProfileSchema.safeParse(body);
      if (!parsed.success) {
        return validationError(parsed.error.errors[0]?.message ?? 'バリデーションエラー');
      }

      const now = new Date().toISOString();
      const existing = await getUser(userId);
      const user = {
        userId,
        nickname: parsed.data.nickname,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      };
      await putUser(user);
      return ok(user);
    }

    return notFound();
  } catch (err) {
    console.error('users handler error:', err);
    return internalError();
  }
};
