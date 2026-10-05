package com.localnote.app.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.localnote.app.data.NoteEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotesListScreen(
    vm: NotesViewModel,
    onNewNote: () -> Unit,
    onOpenNote: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val notes by vm.notes.collectAsState()
    val books by vm.books.collectAsState()
    val query by vm.query.collectAsState()
    val kindFilter by vm.kindFilter.collectAsState()
    val context = LocalContext.current

    var showExportMenu by remember { mutableStateOf(false) }
    var pendingDelete by remember { mutableStateOf<NoteEntity?>(null) }

    val dateFmt = remember { SimpleDateFormat("MM-dd HH:mm", Locale.getDefault()) }
    val bookTitleOf: (String?) -> String? = remember(books) {
        { bookId -> books.firstOrNull { it.id == bookId }?.title }
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text("本地笔记") },
                actions = {
                    IconButton(onClick = { showExportMenu = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "导出")
                    }
                    DropdownMenu(
                        expanded = showExportMenu,
                        onDismissRequest = { showExportMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("导出全部为 Markdown") },
                            onClick = {
                                showExportMenu = false
                                ExportHelper.shareText(context, vm.exportMarkdown(bookTitleOf), "本地笔记.md")
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("导出全部为 TXT") },
                            onClick = {
                                showExportMenu = false
                                ExportHelper.shareText(context, vm.exportText(bookTitleOf), "本地笔记.txt")
                            }
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onNewNote) {
                Icon(Icons.Default.Add, contentDescription = "记一笔")
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp)
        ) {
            OutlinedTextField(
                value = query,
                onValueChange = vm::setQuery,
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("搜索正文、批注") },
                singleLine = true
            )
            Spacer(Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = kindFilter == null,
                    onClick = { vm.setKindFilter(null) },
                    label = { Text("全部") }
                )
                FilterChip(
                    selected = kindFilter == NoteEntity.KIND_INSPIRATION,
                    onClick = { vm.setKindFilter(NoteEntity.KIND_INSPIRATION) },
                    label = { Text("灵感") }
                )
                FilterChip(
                    selected = kindFilter == NoteEntity.KIND_QUOTE,
                    onClick = { vm.setKindFilter(NoteEntity.KIND_QUOTE) },
                    label = { Text("摘句") }
                )
            }
            Spacer(Modifier.height(8.dp))
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(notes, key = { it.id }) { note ->
                    NoteRow(
                        note = note,
                        bookTitle = bookTitleOf(note.bookId),
                        dateText = dateFmt.format(Date(note.createdAt)),
                        onClick = { onOpenNote(note.id) },
                        onDelete = { pendingDelete = note }
                    )
                }
            }
        }
    }

    pendingDelete?.let { note ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text("删除这条笔记？") },
            text = { Text("删除后无法恢复", maxLines = 2, overflow = TextOverflow.Ellipsis) },
            confirmButton = {
                TextButton(onClick = {
                    vm.delete(note)
                    pendingDelete = null
                }) { Text("删除", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) { Text("取消") }
            }
        )
    }
}

@Composable
private fun NoteRow(
    note: NoteEntity,
    bookTitle: String?,
    dateText: String,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        onClick = onClick
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                AssistChip(
                    onClick = {},
                    label = { Text(note.kindName) }
                )
                if (bookTitle != null) {
                    Text(
                        text = "《$bookTitle》",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(start = 8.dp).weight(1f)
                    )
                } else {
                    Spacer(Modifier.weight(1f))
                }
                IconButton(onClick = onDelete) {
                    Icon(Icons.Default.Delete, contentDescription = "删除")
                }
            }
            Text(
                text = note.preview,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = dateText,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
