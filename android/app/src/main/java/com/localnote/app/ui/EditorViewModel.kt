package com.localnote.app.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.localnote.app.data.BookEntity
import com.localnote.app.data.NoteEntity
import com.localnote.app.data.NoteRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/** 新建 / 编辑一条笔记。摘句场景下原文与批注分离存储。 */
class EditorViewModel(
    private val repo: NoteRepository,
    private val noteId: String?
) : ViewModel() {

    var kind by mutableStateOf(NoteEntity.KIND_INSPIRATION)
    var text by mutableStateOf("")
    var annotation by mutableStateOf("")
    var bookId by mutableStateOf<String?>(null)

    val isNew: Boolean get() = noteId == null

    val books: StateFlow<List<BookEntity>> =
        repo.observeBooks()
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        if (noteId != null) {
            viewModelScope.launch {
                repo.getNote(noteId)?.let { n ->
                    kind = n.kind
                    text = n.text
                    annotation = n.annotation
                    bookId = n.bookId
                }
            }
        }
    }

    /** 保存；正文为空返回 false（调用方提示用户） */
    suspend fun save(): Boolean {
        if (text.isBlank()) return false
        val existing = noteId?.let { repo.getNote(it) }
        val note = (existing ?: NoteEntity()).copy(
            kind = kind,
            text = text,
            annotation = annotation,
            bookId = if (kind == NoteEntity.KIND_QUOTE) bookId else null
        )
        repo.saveNote(note)
        return true
    }

    /** 新增一本书，返回其 id */
    suspend fun addBook(title: String, author: String, isbn: String): String {
        val book = BookEntity(title = title.trim(), author = author.trim(), isbn = isbn.trim())
        return repo.saveBook(book)
    }
}
