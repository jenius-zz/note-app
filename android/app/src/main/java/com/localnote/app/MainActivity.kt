package com.localnote.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.localnote.app.data.AppDatabase
import com.localnote.app.data.NoteRepository
import com.localnote.app.ui.EditorViewModel
import com.localnote.app.ui.NoteEditorScreen
import com.localnote.app.ui.NotesListScreen
import com.localnote.app.ui.NotesViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val repo = NoteRepository(AppDatabase.get(this))
        setContent {
            MaterialTheme {
                val nav = rememberNavController()
                NavHost(navController = nav, startDestination = "list") {
                    composable("list") {
                        val vm: NotesViewModel = viewModel { NotesViewModel(repo) }
                        NotesListScreen(
                            vm = vm,
                            onNewNote = { nav.navigate("editor") },
                            onOpenNote = { id -> nav.navigate("editor/$id") }
                        )
                    }
                    composable("editor") {
                        val vm: EditorViewModel = viewModel { EditorViewModel(repo, null) }
                        NoteEditorScreen(vm = vm, onDone = { nav.popBackStack() })
                    }
                    composable("editor/{noteId}") { backStack ->
                        val id = backStack.arguments?.getString("noteId")
                        val vm: EditorViewModel = viewModel(key = "editor_$id") { EditorViewModel(repo, id) }
                        NoteEditorScreen(vm = vm, onDone = { nav.popBackStack() })
                    }
                }
            }
        }
    }
}
