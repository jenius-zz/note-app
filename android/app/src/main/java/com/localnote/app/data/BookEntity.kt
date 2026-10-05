package com.localnote.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

/** 书架上的一本书（ISBN 建书目，首版手动录入） */
@Entity(tableName = "books")
data class BookEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val title: String,
    val author: String = "",
    val isbn: String = "",
    val coverUrl: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)
