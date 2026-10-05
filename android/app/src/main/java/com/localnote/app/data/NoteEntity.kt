package com.localnote.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

/** 一条笔记：灵感 / 读书摘句。全部字段只存本机，不上传云端。 */
@Entity(tableName = "notes")
data class NoteEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val kind: String = KIND_INSPIRATION, // inspiration | quote
    val text: String = "",               // 灵感正文 / 摘句原文
    val annotation: String = "",         // 批注（摘句场景使用）
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val bookId: String? = null
) {
    companion object {
        const val KIND_INSPIRATION = "inspiration"
        const val KIND_QUOTE = "quote"
    }

    val kindName: String get() = if (kind == KIND_QUOTE) "摘句" else "灵感"

    /** 列表页显示的摘要行 */
    val preview: String get() {
        val firstLine = text.trim().lineSequence().firstOrNull().orEmpty()
        return firstLine.ifEmpty { "（空）" }
    }
}
