/* UnixのELF実行ファイル形式とかにはしないでバイナリで出力させる */
OUTPUT_FORMAT("binary")

MEMORY
{
	/* MBR分のサイズ */
	ROM (rx)	: ORIGIN = 0x7c00, LENGTH = 512
}

SECTIONS
{
	/* .textのセクションは、ROMのメモリー領域へ */
	.text : { *(.text) } > ROM
}

