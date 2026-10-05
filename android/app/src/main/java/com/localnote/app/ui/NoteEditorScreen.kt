package com.localnote.app.ui

import android.widget.Toast
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.localnote.app.data.NoteEntity
import com.localnote.app.ui.theme.AccentOrange
import com.localnote.app.ui.theme.Cream
import com.localnote.app.ui.theme.InkBrown
import com.localnote.app.ui.theme.InkSoft
import com.localnote.app.ui.theme.tagColorFor
import kotlinx.coroutines.launch

private val FieldShape = RoundedCornerShape(16.dp)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun journalFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedContainerColor = Color.White,
    unfocusedContainerColor = Color.White.copy(alpha = 0.8f),
    focusedTextColor = InkBrown,
    unfocusedTextColor = InkBrown,
    focusedBorderColor = AccentOrange.copy(alpha = 0.5f),
    unfocusedBorderColor = Color.Transparent,
    cursorColor = AccentOrange,
)

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
        containerColor = Cream,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (vm.isNew) "记一笔" else "编辑",
                        color = InkBrown,
                        fontWeight = FontWeight.Bold
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Cream),
                actions = {
                    Button(
                        onClick = {
                            scope.launch {
                                if (vm.save()) onDone()
                                else Toast.makeText(context, "内容不能为空", Toast.LENGTH_SHORT).show()
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = AccentOrange),
                        shape = RoundedCornerShape(50)
                    ) { Text("保存") }
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
            // 类型切换
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                SegmentedButton(
                    selected = vm.kind == NoteEntity.KIND_INSPIRATION,
                    onClick = { vm.kind = NoteEntity.KIND_INSPIRATION },
                    shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2),
                    colors = SegmentedButtonDefaults.colors(
                        activeContainerColor = tagColorFor(NoteEntity.KIND_INSPIRATION),
                        activeContentColor = Color.White
                    ),
                    label = { Text("灵感", fontWeight = FontWeight.SemiBold) }
                )
                SegmentedButton(
                    selected = isQuote,
                    onClick = { vm.kind = NoteEntity.KIND_QUOTE },
                    shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2),
                    colors = SegmentedButtonDefaults.colors(
                        activeContainerColor = tagColorFor(NoteEntity.KIND_QUOTE),
                        activeContentColor = Color.White
                    ),
                    label = { Text("摘句", fontWeight = FontWeight.SemiBold) }
                )
            }
            Spacer(Modifier.height(12.dp))
            Text(
                if (isQuote) "原文" else "内容",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = InkBrown
            )
            Spacer(Modifier.height(4.dp))
            OutlinedTextField(
                value = vm.text,
                onValueChange = { vm.text = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                placeholder = {
                    Text(
                        if (isQuote) "粘贴或输入书中原文" else "写下你的灵感…",
                        color = InkSoft
                    )
                },
                shape = FieldShape,
                colors = journalFieldColors()
            )
            if (isQuote) {
                Spacer(Modifier.height(12.dp))
                Text(
                    "批注",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = InkBrown
                )
                Spacer(Modifier.height(4.dp))
                OutlinedTextField(
                    value = vm.annotation,
                    onValueChange = { vm.annotation = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("写下你的想法（与原文分开保存）", color = InkSoft) },
                    minLines = 2,
                    shape = FieldShape,
                    colors = journalFieldColors()
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    "归属书籍",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = InkBrown
                )
                Spacer(Modifier.height(4.dp))
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
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            shape = FieldShape,
            colors = journalFieldColors(),
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
        title = { Text("新增书籍", color = InkBrown, fontWeight = FontWeight.Bold) },
        text = {
            Column {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("书名 *") },
                    singleLine = true,
                    shape = FieldShape,
                    colors = journalFieldColors(),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = author,
                    onValueChange = { author = it },
                    label = { Text("作者") },
                    singleLine = true,
                    shape = FieldShape,
                    colors = journalFieldColors(),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = isbn,
                    onValueChange = { isbn = it },
                    label = { Text("ISBN") },
                    singleLine = true,
                    shape = FieldShape,
                    colors = journalFieldColors(),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { if (title.isNotBlank()) onConfirm(title, author, isbn) },
                enabled = title.isNotBlank()
            ) { Text("确定", color = AccentOrange, fontWeight = FontWeight.SemiBold) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("取消", color = InkSoft) }
        }
    )
}
