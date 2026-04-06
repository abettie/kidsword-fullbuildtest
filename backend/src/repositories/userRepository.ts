import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const tableName = process.env.USERS_TABLE ?? 'kidsword-dev-users';

export interface User {
  userId: string;
  nickname: string;
  createdAt: string;
  updatedAt: string;
}

export async function getUser(userId: string): Promise<User | null> {
  const result = await client.send(
    new GetCommand({ TableName: tableName, Key: { userId } })
  );
  return (result.Item as User) ?? null;
}

export async function putUser(user: User): Promise<void> {
  await client.send(new PutCommand({ TableName: tableName, Item: user }));
}
