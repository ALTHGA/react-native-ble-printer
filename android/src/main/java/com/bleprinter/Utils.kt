package com.bleprinter

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import com.bleprinter.enums.Align
import kotlin.experimental.or

public class Utils {

  private val PAPER_WIDTH = 384f

  public fun createTextBitmap(
    text: String,
    align: String,
    bold: Boolean = false,
    fontSize: Float = 24f,
  ): ByteArray {
    val paint = Paint().apply {
      color = Color.BLACK
      textSize = fontSize
      isAntiAlias = true
      typeface =
        if (bold) Typeface.create(Typeface.DEFAULT, Typeface.BOLD) else Typeface.DEFAULT
      textAlign = when (align) {
        "CENTER" -> Paint.Align.CENTER
        "RIGHT" -> Paint.Align.RIGHT
        else -> Paint.Align.LEFT
      }
    }

    // Split text into lines
    val wrappedLines = text.split("\n").flatMap { line ->
      wrapTextToLines(line, paint, PAPER_WIDTH.toInt())
    }

    val fontMetrics = paint.fontMetrics
    val lineHeight = (fontMetrics.descent - fontMetrics.ascent + fontMetrics.leading).toInt() // Adjust line spacing

    // Calculate total bitmap height
    val totalHeight = lineHeight * wrappedLines.size

    // Create a bitmap with enough height for the text
    val bitmap = Bitmap.createBitmap(PAPER_WIDTH.toInt(), totalHeight, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    canvas.drawColor(Color.WHITE)

    // Draw text on canvas
    for ((index, line) in wrappedLines.withIndex()) {
      val yPos = ((index + 1) * lineHeight - fontMetrics.descent).toFloat() // Ajustar posição para descida
      val xPos = when (align) {
        "CENTER" -> PAPER_WIDTH / 2f
        "RIGHT" -> PAPER_WIDTH - 10f
        else -> 10f
      }
      canvas.drawText(line, xPos, yPos, paint)
    }

    return convertBitmapToPrinterArray(bitmap)
  }

  fun line(): ByteArray {

    val paint = Paint().apply {
      color = Color.BLACK
      strokeWidth = 5f
      isAntiAlias = true
    }

    val width = 384
    val height = 50

    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val startX = 0f
    val stopX = width.toFloat()
    val yPosition = height / 2f

    canvas.drawColor(Color.WHITE)
    canvas.drawLine(startX, yPosition, stopX, yPosition, paint)
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
}
