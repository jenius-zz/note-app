package com.localnote.app.ui

import android.content.Context
import android.content.Intent
import com.localnote.app.data.NoteEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** 导出为 Markdown / TXT，简单可靠地经系统分享发出 */
object ExportHelper {

private val fmt = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())

fun buildMarkdown(notes: List<NoteEntity>, bookTitleOf: (String?) -> String?): String =
buildString {
appendLine("# 本地笔记导出")
appendLine()
for (n in notes) {
appendLine("## ${n.kindName} · ${fmt.format(Date(n.createdAt))}")
bookTitleOf(n.bookId)?.let { appendLine("> 出自《$it》")}
appendLine()
appendLine(n.text)
if (n.annotation.isNotBlank()) {
appendLine()
appendLine("**批注**：${n.annotation}")
}
appendLine()
appendLine("---")
appendLine()
}
}

fun buildText(notes: List<NoteEntity>, bookTitleOf: (String?) -> String?): String =
buildString {
for (n in notes) {
appendLine("${fmt.format(Date(n.createdAt))}")
bookTitleOf(n.bookId)?.let { appendLine("出自《$it》")}
appendLine(n.text)
if (n.annotation.isNotBlank()) appendLine("批注：${n.annotation}")
appendLine()
}
}

fun shareText(context: Context, text: String, title: String) {
val intent = Intent(Intent.ACTION_SEND).apply {
type = "text/plain"
putExtra(Intent.EXTRA_TEXT, text)
putExtra(Intent.EXTRA_SUBJECT, title)
}
context.startActivity(Intent.createChooser(intent, "分享"))
}
}
