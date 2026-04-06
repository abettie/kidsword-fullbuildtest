import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { APIGatewayProxyEvent } from 'aws-lambda';

vi.mock('../../middleware/auth.js', () => ({
  verifyToken: vi.fn(),
}));

vi.mock('../../repositories/postRepository.js', () => ({
  createPost: vi.fn(),
  getPostsByUser: vi.fn(),
  getFeedPosts: vi.fn(),
}));

vi.mock('../../repositories/userRepository.js', () => ({
  getUser: vi.fn(),
}));

vi.mock('uuid', () => ({ v4: () => 'mock-uuid' }));

import { handler } from '../posts.js';
import { verifyToken } from '../../middleware/auth.js';
import { createPost, getPostsByUser, getFeedPosts } from '../../repositories/postRepository.js';
import { getUser } from '../../repositories/userRepository.js';

const mockEvent = (overrides: Partial<APIGatewayProxyEvent> = {}): APIGatewayProxyEvent =>
  ({
    httpMethod: 'GET',
    path: '/posts',
    headers: {},
    body: null,
    queryStringParameters: null,
    pathParameters: null,
    ...overrides,
  } as APIGatewayProxyEvent);

describe('POST /posts', () => {
  beforeEach(() => vi.clearAllMocks());

  it('未認証は401を返す', async () => {
    vi.mocked(verifyToken).mockResolvedValue(null);
    const res = await handler(mockEvent({ httpMethod: 'POST', path: '/posts' }));
    expect(res.statusCode).toBe(401);
  });

  it('ニックネーム未設定は403を返す', async () => {
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    vi.mocked(getUser).mockResolvedValue(null);
    const body = JSON.stringify({ mispronounced: 'トウモコロシ', intended: 'トウモロコシ' });
    const res = await handler(mockEvent({ httpMethod: 'POST', path: '/posts', body }));
    expect(res.statusCode).toBe(403);
  });

  it('正常な投稿は201を返す', async () => {
    const user = { userId: 'user-1', nickname: 'パパ', createdAt: '2024-01-01T00:00:00.000Z', updatedAt: '2024-01-01T00:00:00.000Z' };
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    vi.mocked(getUser).mockResolvedValue(user);
    vi.mocked(createPost).mockResolvedValue(undefined);
    const body = JSON.stringify({ mispronounced: 'トウモコロシ', intended: 'トウモロコシ', description: 'テスト' });
    const res = await handler(mockEvent({ httpMethod: 'POST', path: '/posts', body }));
    expect(res.statusCode).toBe(201);
    const parsed = JSON.parse(res.body);
    expect(parsed.mispronounced).toBe('トウモコロシ');
    expect(parsed.postId).toBe('mock-uuid');
  });

  it('mispronouncedが空は400を返す', async () => {
    const user = { userId: 'user-1', nickname: 'パパ', createdAt: '2024-01-01T00:00:00.000Z', updatedAt: '2024-01-01T00:00:00.000Z' };
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    vi.mocked(getUser).mockResolvedValue(user);
    const body = JSON.stringify({ mispronounced: '', intended: 'トウモロコシ' });
    const res = await handler(mockEvent({ httpMethod: 'POST', path: '/posts', body }));
    expect(res.statusCode).toBe(400);
  });
});

describe('GET /posts/me', () => {
  beforeEach(() => vi.clearAllMocks());

  it('自分の投稿一覧を返す', async () => {
    const user = { userId: 'user-1', nickname: 'パパ', createdAt: '2024-01-01T00:00:00.000Z', updatedAt: '2024-01-01T00:00:00.000Z' };
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    vi.mocked(getUser).mockResolvedValue(user);
    vi.mocked(getPostsByUser).mockResolvedValue({ posts: [], lastEvaluatedKey: undefined });
    const res = await handler(mockEvent({ path: '/posts/me' }));
    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).posts).toEqual([]);
  });
});

describe('GET /posts', () => {
  beforeEach(() => vi.clearAllMocks());

  it('全体フィードを返す', async () => {
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    vi.mocked(getFeedPosts).mockResolvedValue({ posts: [], lastEvaluatedKey: undefined });
    const res = await handler(mockEvent({ path: '/posts' }));
    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).posts).toEqual([]);
  });
});
