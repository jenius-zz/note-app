package com.localnote.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.localnote.app.data.BookEntity
import com.localnote.app.data.NoteEntity
import com.localnote.app.data.NoteRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/** 笔记列表：搜索 + 类型筛选 + 导出 */
@OptIn(ExperimentalCoroutinesApi::class)
class NotesViewModel(private val repo: NoteRepository) : ViewModel() {

    private val _query = MutableStateFlow("")
    val query: StateFlow<String> = _query.asStateFlow()

    /** null=全部, "inspiration"=灵感, "quote"=摘句 */
    private val _kindFilter = MutableStateFlow<String?>(null)
    val kindFilter: StateFlow<String?> = _kindFilter.asStateFlow()

    val notes: StateFlow<List<NoteEntity>> =
        combine(_query, _kindFilter) { q, k -> q to k }
            .flatMapLatest { (q, k) -> repo.observeNotes(k, q) }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val books: StateFlow<List<BookEntity>> =
        repo.observeBooks()
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun setQuery(q: String) { _query.value = q }
    fun setKindFilter(kind: String?) { _kindFilter.value = kind }

    fun delete(note: NoteEntity) {
        viewModelScope.launch { repo.deleteNote(note) }
    }

    fun exportMarkdown(bookTitleOf: (String?) -> String?): String =
        ExportHelper.buildMarkdown(notes.value, bookTitleOf)

    fun exportText(bookTitleOf: (String?) -> String?): String =
        ExportHelper.buildText(notes.value, bookTitleOf)
}
