import BlePrinter from 'react-native-ble-printer';
export async function printReceipt() {
  const summaryDateFormatted = Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'medium',
  }).format(new Date());

  await BlePrinter.printText('ArcadeX', {
    align: 'CENTER',
    size: 50,
    bold: true,
  });
  await BlePrinter.printSpace(1);
  await BlePrinter.printText('Ponto: Bar do Montanha');
  await BlePrinter.printText('Rota: São Paulo');
  await BlePrinter.printText(
    'Emissão: ' +
      Intl.DateTimeFormat('pt-BR', { dateStyle: 'medium' }).format(new Date())
  );

  await BlePrinter.printText('Data: ' + summaryDateFormatted);

  await BlePrinter.printSpace(0);
  await BlePrinter.printStroke(20, 5, [10, 5]);
  await BlePrinter.printSpace(0);
  for (let i = 0; i < [0, 1].length; i++) {
    const entryTotal = Math.floor(Math.random() + 1000);
    const paymentTotal = Math.floor(Math.random() + 1000);

    const percentage = 50;

    await BlePrinter.printTwoColumns('Halloween', `${percentage}%`, {
      bold: true,
      size: 30,
    });

    await BlePrinter.printStroke(20, 3);
    await BlePrinter.printColumns(
      ['ENTRADA', 'ATUAL', 'ANTERIOR'],
      [128, 128, 128],
      ['LEFT', 'RIGHT', 'RIGHT'],
      { size: 20, bold: true }
    );
    await BlePrinter.printStroke(20, 3);
    await BlePrinter.printColumns(
      [entryTotal.toString(), entryTotal.toString()],
      [256, 128],
      ['RIGHT', 'RIGHT']
    );
    await BlePrinter.printText(entryTotal.toFixed(0), { align: 'RIGHT' });
    await BlePrinter.printStroke(20, 3);

    await BlePrinter.printColumns(
      ['SAÍDA', 'ATUAL', 'ANTERIOR'],
      [128, 128, 128],
      ['LEFT', 'RIGHT', 'RIGHT'],
      { size: 20, bold: true }
    );
    await BlePrinter.printStroke(20, 3);
    await BlePrinter.printColumns(
      [paymentTotal.toString(), paymentTotal.toString()],
      [250, 128],
      ['RIGHT', 'RIGHT']
    );

    await BlePrinter.printText(entryTotal.toFixed(0), { align: 'RIGHT' });
    await BlePrinter.printStroke(20, 3);
    await BlePrinter.printColumns(
      ['TOTAL', 'SALDO', 'COMISSÃO'],
      [128, 128, 128],
      ['LEFT', 'RIGHT', 'RIGHT'],
      { size: 20, bold: true }
    );
    await BlePrinter.printStroke(20, 3);
    await BlePrinter.printColumns(
      ['1000', '432', '432'],
      [128, 128, 128],
      ['LEFT', 'RIGHT', 'RIGHT']
    );

    await BlePrinter.printSpace(0);
    await BlePrinter.printStroke(20, 5, [10, 5]);
  }

  await BlePrinter.printTwoColumns('T.ENTRADA..', (2321).toFixed(0));
  await BlePrinter.printTwoColumns('T.SAIDA..', (32143).toFixed(0));

  await BlePrinter.printSpace(5);
}
