package com.localnote.app.data

import kotlinx.coroutines.flow.Flow

class NoteRepository(private val db: AppDatabase) {
    private val noteDao = db.noteDao()
    private val bookDao = db.bookDao()

    fun observeNotes(kind: String?, query: String): Flow<List<NoteEntity>> =
        noteDao.observeFiltered(kind, query.trim())

    fun observeBooks(): Flow<List<BookEntity>> = bookDao.observeAll()

    suspend fun getNote(id: String): NoteEntity? = noteDao.getById(id)

    suspend fun saveNote(note: NoteEntity) =
        noteDao.upsert(note.copy(updatedAt = System.currentTimeMillis()))

    suspend fun deleteNote(note: NoteEntity) = noteDao.delete(note)

    suspend fun saveBook(book: BookEntity): String {
        bookDao.upsert(book)
        return book.id
    }

    suspend fun getBook(id: String): BookEntity? = bookDao.getById(id)
}
