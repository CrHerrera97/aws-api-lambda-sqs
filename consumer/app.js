exports.handler = async (event) => {
  for (const record of event.Records) {
    const pedido = JSON.parse(record.body);
    console.log("📦 Procesando pedido:", pedido);

    
  }

  return { status: "OK" };
};
