package com.localnote.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.localnote.app.data.NoteEntity
import com.localnote.app.ui.theme.AccentOrange
import com.localnote.app.ui.theme.Cream
import com.localnote.app.ui.theme.InkBrown
import com.localnote.app.ui.theme.InkSoft
import com.localnote.app.ui.theme.TagOrange
import com.localnote.app.ui.theme.cardColorFor
import com.localnote.app.ui.theme.tagColorFor
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
        containerColor = Cream,
        floatingActionButton = {
            FloatingActionButton(
                onClick = onNewNote,
                containerColor = AccentOrange,
                contentColor = Color.White,
                shape = CircleShape
            ) {
                Icon(Icons.Default.Add, contentDescription = "记一笔")
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // 标题行
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp)
            ) {
                Text(
                    text = "灵感笔记",
                    style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.Bold),
                    color = InkBrown,
                    modifier = Modifier.weight(1f)
                )
                IconButton(onClick = { showExportMenu = true }) {
                    Icon(Icons.Default.MoreVert, contentDescription = "导出", tint = InkBrown)
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
            // 日期行
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 2.dp)
            ) {
                Text(
                    text = dateRowText(),
                    style = MaterialTheme.typography.bodyLarge,
                    color = InkBrown,
                    modifier = Modifier.weight(1f)
                )
                Text("✦", color = TagOrange.copy(alpha = 0.6f))
            }
            Spacer(Modifier.height(8.dp))
            // 搜索框
            TextField(
                value = query,
                onValueChange = vm::setQuery,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                placeholder = { Text("搜索笔记…", color = InkSoft) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = InkSoft) },
                singleLine = true,
                shape = RoundedCornerShape(20.dp),
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color.White.copy(alpha = 0.75f),
                    unfocusedContainerColor = Color.White.copy(alpha = 0.75f),
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    focusedTextColor = InkBrown,
                    unfocusedTextColor = InkBrown,
                )
            )
            Spacer(Modifier.height(8.dp))
            // 类型筛选
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(horizontal = 16.dp)
            ) {
                JournalFilterChip("全部", kindFilter == null) { vm.setKindFilter(null) }
                JournalFilterChip("灵感", kindFilter == NoteEntity.KIND_INSPIRATION) {
                    vm.setKindFilter(NoteEntity.KIND_INSPIRATION)
                }
                JournalFilterChip("摘句", kindFilter == NoteEntity.KIND_QUOTE) {
                    vm.setKindFilter(NoteEntity.KIND_QUOTE)
                }
            }
            Spacer(Modifier.height(8.dp))
            // 列表
            if (notes.isEmpty()) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 60.dp)
                ) {
                    Text("✎", style = MaterialTheme.typography.headlineLarge, color = InkSoft)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        if (query.isEmpty()) "还没有笔记，去记一笔吧" else "没有匹配的笔记",
                        color = InkSoft
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(
                        start = 16.dp, end = 16.dp, bottom = 96.dp
                    )
                ) {
                    items(notes, key = { it.id }) { note ->
                        NoteCard(
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
private fun JournalFilterChip(
    title: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = { Text(title, fontWeight = FontWeight.SemiBold) },
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = InkBrown,
            selectedLabelColor = Color.White,
            containerColor = Color.White.copy(alpha = 0.7f),
            labelColor = InkBrown
        )
    )
}

private fun dateRowText(): String {
    val now = Date()
    val df = SimpleDateFormat("M月d日", Locale.CHINA)
    val wf = SimpleDateFormat("EEEE", Locale.CHINA)
    return "今天 · ${df.format(now)} ${wf.format(now)}"
}

@Composable
private fun NoteCard(
    note: NoteEntity,
    bookTitle: String?,
    dateText: String,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    androidx.compose.material3.Card(
        modifier = modifier.fillMaxWidth(),
        onClick = onClick,
        shape = RoundedCornerShape(20.dp),
        colors = androidx.compose.material3.CardDefaults.cardColors(
            containerColor = cardColorFor(note.kind)
        ),
        elevation = androidx.compose.material3.CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(tagColorFor(note.kind))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = note.kindName,
                        color = Color.White,
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                if (bookTitle != null) {
                    Text(
                        text = "《$bookTitle》",
                        style = MaterialTheme.typography.labelMedium,
                        color = InkSoft,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier
                            .padding(start = 8.dp)
                            .weight(1f)
                    )
                } else {
                    Spacer(Modifier.weight(1f))
                }
                IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Default.Delete, contentDescription = "删除", tint = InkSoft)
                }
            }
            Spacer(Modifier.height(8.dp))
            Text(
                text = note.preview,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
                style = MaterialTheme.typography.bodyLarge,
                color = InkBrown
            )
            Spacer(Modifier.height(4.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = dateText,
                    style = MaterialTheme.typography.labelMedium,
                    color = InkSoft,
                    modifier = Modifier.weight(1f)
                )
                Text("✦", style = MaterialTheme.typography.labelSmall, color = InkSoft.copy(alpha = 0.4f))
            }
        }
    }
}
