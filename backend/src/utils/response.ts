import type { APIGatewayProxyResult } from 'aws-lambda';

export function ok(body: unknown): APIGatewayProxyResult {
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

export function created(body: unknown): APIGatewayProxyResult {
  return {
    statusCode: 201,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

export function error(
  statusCode: number,
  code: string,
  message: string
): APIGatewayProxyResult {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ error: { code, message } }),
  };
}

export const unauthorized = () =>
  error(401, 'UNAUTHORIZED', '認証トークンが無効または期限切れです');

export const forbidden = (message = 'アクセス権限がありません') =>
  error(403, 'FORBIDDEN', message);

export const notFound = (message = 'リソースが存在しません') =>
  error(404, 'NOT_FOUND', message);

export const validationError = (message: string) =>
  error(400, 'VALIDATION_ERROR', message);

export const internalError = () =>
  error(500, 'INTERNAL_ERROR', 'サーバ内部エラーが発生しました');
