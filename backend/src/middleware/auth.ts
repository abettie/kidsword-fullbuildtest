import { GetSecretValueCommand, SecretsManagerClient } from '@aws-sdk/client-secrets-manager';
import * as admin from 'firebase-admin';
import type { APIGatewayProxyEvent } from 'aws-lambda';

let initialized = false;

async function initFirebase(): Promise<void> {
  if (initialized) return;

  const secretName = process.env.FIREBASE_SECRET_NAME;
  if (!secretName) throw new Error('FIREBASE_SECRET_NAME is not set');

  const client = new SecretsManagerClient({ region: process.env.AWS_REGION ?? 'ap-northeast-1' });
  const result = await client.send(new GetSecretValueCommand({ SecretId: secretName }));

  if (!result.SecretString) throw new Error('Failed to retrieve Firebase secret');

  const serviceAccount = JSON.parse(result.SecretString) as admin.ServiceAccount;

  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  initialized = true;
}

export async function verifyToken(event: APIGatewayProxyEvent): Promise<string | null> {
  const authHeader = event.headers['Authorization'] ?? event.headers['authorization'];
  if (!authHeader?.startsWith('Bearer ')) return null;

  const token = authHeader.slice(7);

  try {
    await initFirebase();
    const decoded = await admin.auth().verifyIdToken(token);
    return decoded.uid;
  } catch {
    return null;
  }
}
