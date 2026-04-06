import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { APIGatewayProxyEvent } from 'aws-lambda';

vi.mock('../../middleware/auth.js', () => ({
  verifyToken: vi.fn(),
}));

vi.mock('../../repositories/userRepository.js', () => ({
  getUser: vi.fn(),
  putUser: vi.fn(),
}));

import { handler } from '../users.js';
import { verifyToken } from '../../middleware/auth.js';
import { getUser, putUser } from '../../repositories/userRepository.js';

const mockEvent = (overrides: Partial<APIGatewayProxyEvent> = {}): APIGatewayProxyEvent =>
  ({
    httpMethod: 'GET',
    path: '/users/me',
    headers: {},
    body: null,
    queryStringParameters: null,
    pathParameters: null,
    ...overrides,
  } as APIGatewayProxyEvent);

describe('GET /users/me', () => {
  beforeEach(() => vi.clearAllMocks());

  it('未認証のリクエストは401を返す', async () => {
    vi.mocked(verifyToken).mockResolvedValue(null);
    const res = await handler(mockEvent());
    expect(res.statusCode).toBe(401);
  });

  it('ユーザが存在しない場合は404を返す', async () => {
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    vi.mocked(getUser).mockResolvedValue(null);
    const res = await handler(mockEvent());
    expect(res.statusCode).toBe(404);
  });

  it('ユーザが存在する場合は200とユーザ情報を返す', async () => {
    const user = { userId: 'user-1', nickname: 'パパ', createdAt: '2024-01-01T00:00:00.000Z', updatedAt: '2024-01-01T00:00:00.000Z' };
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    vi.mocked(getUser).mockResolvedValue(user);
    const res = await handler(mockEvent());
    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body)).toEqual(user);
  });
});

describe('PUT /users/me', () => {
  beforeEach(() => vi.clearAllMocks());

  it('nicknameが空の場合は400を返す', async () => {
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    const res = await handler(mockEvent({ httpMethod: 'PUT', body: JSON.stringify({ nickname: '' }) }));
    expect(res.statusCode).toBe(400);
  });

  it('nicknameが21文字以上の場合は400を返す', async () => {
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    const res = await handler(mockEvent({ httpMethod: 'PUT', body: JSON.stringify({ nickname: 'a'.repeat(21) }) }));
    expect(res.statusCode).toBe(400);
  });

  it('正常なnicknameで200とユーザ情報を返す', async () => {
    vi.mocked(verifyToken).mockResolvedValue('user-1');
    vi.mocked(getUser).mockResolvedValue(null);
    vi.mocked(putUser).mockResolvedValue(undefined);
    const res = await handler(mockEvent({ httpMethod: 'PUT', body: JSON.stringify({ nickname: 'パパ' }) }));
    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.nickname).toBe('パパ');
    expect(body.userId).toBe('user-1');
  });
});
