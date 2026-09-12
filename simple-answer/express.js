const express = require('express');
const winston = require('winston');
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");

const app = express();
const port = 3000;
const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = "simple-answer";
const ITEM_ID = "simple-answer";
const ANSWER_ATTRIBUTE = "the-answer-to-life-the-universe-and-everything";

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [new winston.transports.Console()],
});

const getSimpleAnswer = async () => {
  const data = await docClient.send(new GetCommand({
    TableName: TABLE_NAME,
    Key: { id: ITEM_ID },
  }));

  if (!data.Item) {
    throw new Error(`Item '${ITEM_ID}' not found in table '${TABLE_NAME}'`);
  }

  return data.Item[ANSWER_ATTRIBUTE];
};

app.get('/', async (req, res) => {
  try {
    const answer = await getSimpleAnswer();
    logger.info('resolved answer', { answer });
    res.send(`The Answer To Life The Universe And Everything is: ${answer}`);
  } catch (err) {
    logger.error('failed to read answer from DynamoDB', { error: err.message });
    res.status(500).json({ error: 'internal error' });
  }
});

app.listen(port, () => {
  logger.info(`Example app listening on port ${port}`);
});
