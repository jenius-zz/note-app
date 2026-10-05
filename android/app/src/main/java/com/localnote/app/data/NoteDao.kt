package com.localnote.app.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface NoteDao {

    /** 列表 + 类型筛选 + 全文搜索（正文/批注），按创建时间倒序 */
    @Query(
        """
        SELECT * FROM notes
        WHERE (:kind IS NULL OR kind = :kind)
        AND (:q = '' OR text LIKE '%' || :q || '%' OR annotation LIKE '%' || :q || '%')
        ORDER BY createdAt DESC
        """
    )
    fun observeFiltered(kind: String?, q: String): Flow<List<NoteEntity>>

    @Query("SELECT * FROM notes WHERE id = :id")
    suspend fun getById(id: String): NoteEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(note: NoteEntity)

    @Delete
    suspend fun delete(note: NoteEntity)
}
