const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { v4: uuidv4 } = require("uuid");

const client = new DynamoDBClient();
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME;

exports.handler = async (event) => {
  for (const record of event.Records) {
    try {
      const pedido = JSON.parse(record.body);

      const id = pedido.id ? String(pedido.id) : uuidv4();

      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          id: id,
          ...pedido,
          fecha: new Date().toISOString(),
        }
      }));

      console.log("✅ Pedido guardado en DynamoDB:", pedido);
    } catch (err) {
      console.error("❌ Error procesando pedido:", err);
    }
  }

  return { statusCode: 200 };
};