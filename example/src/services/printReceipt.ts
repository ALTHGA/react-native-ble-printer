import BlePrinter from 'react-native-ble-printer';
export async function printReceipt() {
  BlePrinter.printLines(2);
  BlePrinter.printText('BUSINESS NAME', {
    size: 40,
    bold: true,
    align: 'CENTER',
  });
  BlePrinter.printLines(2);
  BlePrinter.printText('1234 Main Street\nSuite 567', { align: 'CENTER' });
  BlePrinter.printText('City Name, State 54321\n123-456-7890', {
    align: 'CENTER',
  });
  BlePrinter.printUnderline();
  BlePrinter.printColumns('Lorem ipsum', '$1.25');
  BlePrinter.printColumns('Dolor sit amet', '$7.25');
  BlePrinter.printColumns('Consectetur', '$26.75');
  BlePrinter.printColumns('Adipiscing elit', '$15.49');
  BlePrinter.printColumns('Sed semper', '$18.79');
  BlePrinter.printColumns('Accumsan ante', '$42.99');
  BlePrinter.printColumns('Non laoreet', '$9.99');
  BlePrinter.printColumns('Dui dapibus eu', '$27.50');
  BlePrinter.printLines(2);
  BlePrinter.printColumns('Sub Total', '$150.70');
  BlePrinter.printColumns('Sales tax', '$5.29');
  BlePrinter.printUnderline();
  BlePrinter.printColumns('TOTAL', '$155.99', { bold: true, size: 30 });
  BlePrinter.printUnderline();
  BlePrinter.printColumns('Paid By:', 'Credit');
  BlePrinter.printLines(2);
  BlePrinter.printText('26/12/2024 11:09 PM');
  BlePrinter.printText('Transaction ID: 234-567890');
  BlePrinter.printText('Vendor ID: 987654-321');
  BlePrinter.printLines(3);
  BlePrinter.printText('THANK YOU FOR SUPPORTING\nLOCAL BUSINESS', {
    align: 'CENTER',
    bold: true,
    size: 27,
  });
  BlePrinter.printLines(5);
}
