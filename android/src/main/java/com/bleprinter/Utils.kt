package com.bleprinter

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.icu.text.ListFormatter.Width
import com.bleprinter.enums.Align
import kotlin.experimental.or

public class Utils {

  private val PAPER_WIDTH = 384f

  private fun getPaint(
    align: String? = null,
    bold: Boolean = false,
    fontSize: Float = 24f
  ): Paint {
    val paint = Paint().apply {
      color = Color.BLACK
      textSize = fontSize
      isAntiAlias = true
      typeface =
        if (bold) Typeface.create(Typeface.DEFAULT, Typeface.BOLD) else Typeface.DEFAULT
    }

    if(align != null) {
      paint.textAlign = when (align) {
        "CENTER" -> Paint.Align.CENTER
        "RIGHT" -> Paint.Align.RIGHT
        else -> Paint.Align.LEFT
      }
    }

    return paint
  }

  public fun createTextBitmap(
    text: String,
    align: String,
    bold: Boolean = false,
    fontSize: Float = 24f,
  ): ByteArray {
    val paint = getPaint(align, bold, fontSize)

    // Split text into lines
    val wrappedLines = text.split("\n").flatMap { line ->
      wrapTextToLines(line, paint, PAPER_WIDTH.toInt())
    }

    val fontMetrics = paint.fontMetrics
    val lineHeight =
      (fontMetrics.descent - fontMetrics.ascent + fontMetrics.leading).toInt() // Adjust line spacing

    // Calculate total bitmap height
    val totalHeight = lineHeight * wrappedLines.size

    // Create a bitmap with enough height for the text
    val bitmap = Bitmap.createBitmap(PAPER_WIDTH.toInt(), totalHeight, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    canvas.drawColor(Color.WHITE)

    // Draw text on canvas
    for ((index, line) in wrappedLines.withIndex()) {
      val yPos =
        ((index + 1) * lineHeight - fontMetrics.descent).toFloat() // Ajustar posição para descida
      val xPos = when (align) {
        "CENTER" -> PAPER_WIDTH / 2f
        "RIGHT" -> PAPER_WIDTH - 10f
        else -> 10f
      }
      canvas.drawText(line, xPos, yPos, paint)
    }

    return convertBitmapToPrinterArray(bitmap)
  }

  fun createColumnTextBitmap(
    texts: Array<String>,
    widths: Array<Int>,
    alignments: Array<String>,
    bold: Boolean,
    size: Float
  ): ByteArray {
    val paint = getPaint(bold = bold, fontSize = size)

    if (texts.size != widths.size || texts.size != alignments.size) {
      throw IllegalArgumentException("texts, widths, and alignments must have the same size.")
    }

    // Calculate the total height required for the text
    val lineHeight = paint.fontMetrics.bottom - paint.fontMetrics.top
    val bitmapHeight = lineHeight.toInt()

    // Create a bitmap with the correct paper width and calculated height
    val bitmap = Bitmap.createBitmap(PAPER_WIDTH.toInt(), bitmapHeight, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    canvas.drawColor(Color.WHITE) // Background color

    // Draw each column
    var xOffset = 0
    for (i in texts.indices) {
      val text = texts[i]
      val width = widths[i]
      val alignment = alignments[i].uppercase()

      val textWidth = paint.measureText(text)
      val adjustedText = when {
        textWidth > width -> text.substring(0, paint.breakText(text, true, width.toFloat(), null))
        else -> text
      }

      val xPosition = when (alignment) {
        "LEFT" -> xOffset + 10f
        "RIGHT" -> xOffset + (width - textWidth).toInt() - 10f
        "CENTER" -> xOffset + ((width - textWidth) / 2).toInt()
        else -> throw IllegalArgumentException("Invalid alignment: $alignment")
      }

      // Draw text
      canvas.drawText(adjustedText, xPosition.toFloat(), -paint.fontMetrics.top, paint)
      xOffset += width // Move to the next column
    }

    return convertBitmapToPrinterArray(bitmap)
  }

  fun createStyledStrokeBitmap(
    strokeHeight: Int,
    strokeWidth: Float,
    dashPattern: FloatArray? = null
  ): ByteArray {
    val bitmap = Bitmap.createBitmap(PAPER_WIDTH.toInt(), strokeHeight, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    canvas.drawColor(Color.WHITE) // Background color

    // Draw the styled stroke
    drawStyledStroke(
      canvas = canvas,
      startX = 0f,
      startY = strokeHeight / 2f,
      endX = PAPER_WIDTH,
      endY = strokeHeight / 2f,
      strokeWidth = strokeWidth,
      strokeColor = Color.BLACK,
      dashPattern = dashPattern
    )

    return convertBitmapToPrinterArray(bitmap)
  }


  fun convertBitmapToPrinterArray(bitmap: Bitmap): ByteArray {
    val width = bitmap.width
    val height = bitmap.height
    val pixels = IntArray(width * height)
    bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

    val bytesPerRow = (width + 7) / 8 // Calculate the number of bytes per row
    val result = ByteArray(bytesPerRow * height)

    for (y in 0 until height) {
      for (x in 0 until width) {
        val pixelIndex = y * width + x
        val byteIndex = y * bytesPerRow + x / 8
        val bitIndex = 7 - (x % 8)

        val color = pixels[pixelIndex]
        val isBlack = (color and 0xFF) < 128 // Check if pixel is "black" (threshold)

        if (isBlack) {
          result[byteIndex] = result[byteIndex] or (1 shl bitIndex).toByte()
        }
      }
    }

    return addPrinterCommand(result)
  }

  private fun addPrinterCommand(data: ByteArray): ByteArray {
    val header = byteArrayOf(0x1D, 0x76, 0x30, 0x00) // ESC * command
    val widthBytes = byteArrayOf((PAPER_WIDTH.toInt() / 8).toByte(), 0x00)
    val heightBytes = byteArrayOf((data.size / (PAPER_WIDTH.toInt() / 8)).toByte(), 0x00)

    return header + widthBytes + heightBytes + data
  }


  fun wrapTextToLines(text: String, paint: Paint, maxWidth: Int): List<String> {
    val lines = mutableListOf<String>()
    var remainingText = text

    while (remainingText.isNotEmpty()) {
      val count = paint.breakText(remainingText, true, maxWidth.toFloat(), null)
      lines.add(remainingText.substring(0, count))
      remainingText = remainingText.substring(count)
    }

    return lines
  }

  fun twoColumnsBitmap(
    leftText: String,
    rightText: String,
    bold: Boolean = false,
    size: Float = 24f,
  ): ByteArray {
    val paperWidth = PAPER_WIDTH
    val paint = getPaint(bold = bold, fontSize = size)

    // Calcula as larguras dos textos
    val leftWidth = paint.measureText(leftText)
    val rightWidth = paint.measureText(rightText)

    // Valida se o texto cabe no papel
    if (leftWidth + rightWidth > paperWidth) {
      throw IllegalArgumentException("Os textos são muito largos para caber na largura do papel.")
    }

    // Calcula a posição da coluna da direita
    val lineHeight = paint.fontMetrics.bottom - paint.fontMetrics.top
    val bitmapHeight = lineHeight.toInt()

    // Cria o bitmap
    val bitmap = Bitmap.createBitmap(paperWidth.toInt(), bitmapHeight, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    canvas.drawColor(Color.WHITE)

    // Desenha o texto da esquerda
    val leftX = 0f
    val leftY = -paint.fontMetrics.top
    canvas.drawText(leftText, leftX + 10f, leftY, paint)

    // Desenha o texto da direita
    val rightX = paperWidth - rightWidth
    canvas.drawText(rightText, rightX - 10f, leftY, paint)

    return convertBitmapToPrinterArray(bitmap)
  }

  fun drawStyledStroke(
    canvas: Canvas,
    startX: Float,
    startY: Float,
    endX: Float,
    endY: Float,
    strokeWidth: Float,
    strokeColor: Int,
    dashPattern: FloatArray? = null // Optional dash pattern
  ) {
    val paint = Paint().apply {
      color = strokeColor
      style = Paint.Style.STROKE
      this.strokeWidth = strokeWidth
      isAntiAlias = true

      // Set dash effect if provided
      dashPattern?.let {
        pathEffect = DashPathEffect(it, 0f)
      }
    }

    canvas.drawLine(startX, startY, endX, endY, paint)
  }
}
