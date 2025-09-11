const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");

const sqs = new SQSClient();

const QUEUE_URL = process.env.QUEUE_URL;

exports.handler = async (event) => {
  try {
    const body = typeof event.body === "string" ? JSON.parse(event.body) : event.body;

    const command = new SendMessageCommand({
      QueueUrl: QUEUE_URL,
      MessageBody: JSON.stringify(body),
    });

    await sqs.send(command);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Pedido enviado a la cola",
        pedido: body,
      }),
    };
  } catch (err) {
    console.error("Error en Producer:", err);
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
