import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  QueryCommand,
} from '@aws-sdk/lib-dynamodb';

const client = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const tableName = process.env.POSTS_TABLE ?? 'kidsword-dev-posts';

export interface Post {
  postId: string;
  userId: string;
  mispronounced: string;
  intended: string;
  description?: string;
  createdAt: string;
  feedPartition: 'ALL';
}

export interface PostWithNickname extends Post {
  nickname: string;
}

export async function createPost(post: Post): Promise<void> {
  await client.send(new PutCommand({ TableName: tableName, Item: post }));
}

export async function getPostsByUser(
  userId: string,
  limit: number,
  exclusiveStartKey?: Record<string, unknown>
): Promise<{ posts: Post[]; lastEvaluatedKey?: Record<string, unknown> }> {
  const result = await client.send(
    new QueryCommand({
      TableName: tableName,
      IndexName: 'GSI1-userId-createdAt',
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: { ':userId': userId },
      ScanIndexForward: false,
      Limit: limit,
      ExclusiveStartKey: exclusiveStartKey,
    })
  );
  return {
    posts: (result.Items as Post[]) ?? [],
    lastEvaluatedKey: result.LastEvaluatedKey as Record<string, unknown> | undefined,
  };
}

export async function getFeedPosts(
  limit: number,
  exclusiveStartKey?: Record<string, unknown>
): Promise<{ posts: Post[]; lastEvaluatedKey?: Record<string, unknown> }> {
  const result = await client.send(
    new QueryCommand({
      TableName: tableName,
      IndexName: 'GSI2-feedPartition-createdAt',
      KeyConditionExpression: 'feedPartition = :all',
      ExpressionAttributeValues: { ':all': 'ALL' },
      ScanIndexForward: false,
      Limit: limit,
      ExclusiveStartKey: exclusiveStartKey,
    })
  );
  return {
    posts: (result.Items as Post[]) ?? [],
    lastEvaluatedKey: result.LastEvaluatedKey as Record<string, unknown> | undefined,
  };
}
