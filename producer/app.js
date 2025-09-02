const AWS = require("aws-sdk");
const sqs = new AWS.SQS();

const QUEUE_URL = process.env.QUEUE_URL;

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body); // { pedidoId, producto, cantidad }

    const params = {
      QueueUrl: QUEUE_URL,
      MessageBody: JSON.stringify(body),
    };

    await sqs.sendMessage(params).promise();

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Pedido enviado a la cola", pedido: body }),
    };
  } catch (err) {
    console.error("Error en Producer:", err);
    return { statusCode: 500, body: JSON.stringify({ error: "Error enviando pedido" }) };
  }
};
