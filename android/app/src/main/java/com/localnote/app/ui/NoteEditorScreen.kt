package com.localnote.app.ui

import android.widget.Toast
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.localnote.app.data.NoteEntity
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NoteEditorScreen(
    vm: EditorViewModel,
    onDone: () -> Unit,
    modifier: Modifier = Modifier
) {
    val books by vm.books.collectAsState()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    var showAddBook by remember { mutableStateOf(false) }

    val isQuote = vm.kind == NoteEntity.KIND_QUOTE

    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(if (vm.isNew) "记一笔" else "编辑") },
                actions = {
                    Button(onClick = {
                        scope.launch {
                            if (vm.save()) onDone()
                            else Toast.makeText(context, "内容不能为空", Toast.LENGTH_SHORT).show()
                        }
                    }) { Text("保存") }
                }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(16.dp)
        ) {
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                SegmentedButton(
                    selected = vm.kind == NoteEntity.KIND_INSPIRATION,
                    onClick = { vm.kind = NoteEntity.KIND_INSPIRATION },
                    shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2),
                    label = { Text("灵感") }
                )
                SegmentedButton(
                    selected = isQuote,
                    onClick = { vm.kind = NoteEntity.KIND_QUOTE },
                    shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2),
                    label = { Text("摘句") }
                )
            }
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(
                value = vm.text,
                onValueChange = { vm.text = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                label = { Text(if (isQuote) "原文" else "内容") },
                placeholder = { Text(if (isQuote) "粘贴或输入书中原文" else "写下你的灵感…") }
            )
            if (isQuote) {
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = vm.annotation,
                    onValueChange = { vm.annotation = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("批注") },
                    placeholder = { Text("写下你的想法（与原文分开保存）") },
                    minLines = 2
                )
                Spacer(Modifier.height(12.dp))
                BookPicker(
                    books = books,
                    selectedId = vm.bookId,
                    onSelect = { vm.bookId = it },
                    onAddBook = { showAddBook = true }
                )
            }
        }
    }

    if (showAddBook) {
        AddBookDialog(
            onDismiss = { showAddBook = false },
            onConfirm = { title, author, isbn ->
                scope.launch {
                    vm.bookId = vm.addBook(title, author, isbn)
                    showAddBook = false
                }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BookPicker(
    books: List<com.localnote.app.data.BookEntity>,
    selectedId: String?,
    onSelect: (String?) -> Unit,
    onAddBook: () -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedTitle = books.firstOrNull { it.id == selectedId }?.title ?: "不归属"

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it },
        modifier = modifier.fillMaxWidth()
    ) {
        OutlinedTextField(
            value = selectedTitle,
            onValueChange = {},
            readOnly = true,
            label = { Text("归属书籍") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .menuAnchor()
                .fillMaxWidth()
        )
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            DropdownMenuItem(
                text = { Text("不归属") },
                onClick = { onSelect(null); expanded = false }
            )
            books.forEach { book ->
                DropdownMenuItem(
                    text = { Text("《${book.title}》${if (book.author.isNotBlank()) " · ${book.author}" else ""}") },
                    onClick = { onSelect(book.id); expanded = false }
                )
            }
            DropdownMenuItem(
                text = { Text("＋ 新增书籍…") },
                onClick = { expanded = false; onAddBook() }
            )
        }
    }
}

@Composable
private fun AddBookDialog(
    onDismiss: () -> Unit,
    onConfirm: (title: String, author: String, isbn: String) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var author by remember { mutableStateOf("") }
    var isbn by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("新增书籍") },
        text = {
            Column {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("书名 *") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = author,
                    onValueChange = { author = it },
                    label = { Text("作者") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = isbn,
                    onValueChange = { isbn = it },
                    label = { Text("ISBN") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { if (title.isNotBlank()) onConfirm(title, author, isbn) },
                enabled = title.isNotBlank()
            ) { Text("确定") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("取消") }
        }
    )
}
