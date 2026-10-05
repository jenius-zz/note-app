package com.localnote.app.ui.theme

import androidx.compose.ui.graphics.Color
import com.localnote.app.data.NoteEntity

/** 温暖手账风色板（与 iOS AppTheme 对齐） */
val Cream = Color(0xFFFFF9F0)          // 奶油暖白底
val CardPeach = Color(0xFFFFE3C2)      // 灵感卡片：蜜桃粉
val CardBlue = Color(0xFFD6E9F8)       // 摘句卡片：雾蓝
val CardMint = Color(0xFFDFF2D8)       // 默认卡片：薄荷绿
val TagOrange = Color(0xFFF97316)      // 灵感标签 / 主按钮：暖橙
val TagBlue = Color(0xFF6AA5DC)        // 摘句标签：雾蓝（加深保证白字可读）
val AccentOrange = Color(0xFFF97316)   // 悬浮按钮：暖橙
val InkBrown = Color(0xFF4A3728)       // 正文：深棕灰
val InkSoft = Color(0xFF9A8A76)         // 次要文字：暖灰

/** 按笔记类型取卡片底色 */
fun cardColorFor(kind: String): Color = when (kind) {
    NoteEntity.KIND_QUOTE -> CardBlue
    else -> CardPeach
}

/** 按笔记类型取标签底色 */
fun tagColorFor(kind: String): Color = when (kind) {
    NoteEntity.KIND_QUOTE -> TagBlue
    else -> TagOrange
}
