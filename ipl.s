	.file "helloos.s"

	.equ	CYLS, 10
	
.code16
.text
	jmp entry		# entryから処理を開始する
	
	# FAT12 フロッピーディスクであることの宣言
	.byte	0x90
	.ascii 	"AOMUSHI "	# ブートセクタの名前(8バイト)
	.word 	512		# 1セクタのサイズ
	.byte 	1		# クラスタのサイズ
	.word 	1		# FATの開始位置
	.byte 	2		# FATの個数
	.word 	224		# ルートディレクトリ領域の大きさ
	.word	2880		# このドライブのセクタ数
	.byte	0xf0		# メディアのタイプ(固定)
	.word	9		# FAT領域のセクタ数
	.word	18		# 1トラックのセクタ数
	.word	2		# ヘッドの数
	.int	0		# パーティションの数(使ってないので0)
	.int	2880		# ドライブの大きさをもう一度
	.byte	0, 0, 0x29	# 不明
	.int	0xffffffff	# ボリュームシリアル番号？
	.ascii	"AOMUSHI-OS "	# ディスクの名前(11バイト)
	.ascii	"FAT12   "	# フォーマットの名前(8バイト)
	.skip	18, 0x00	# 18バイト空けておく
	
entry:	# プログラム本体	
	# 各種レジスタの初期化
	movw	$0, %ax
	movw	%ax, %ss
	movw	$0x7c00, %sp
	movw	%ax, %ds

	# ディスク・データの読み込み先セグメントを設定。(%es, %bx)に読み込まれる。
	movw	$0x0820, %ax
	movw	%ax, %es

	movb	$0, %ch		# シリンダ0
	movb	$0, %dh		# ヘッド0
	movb	$2, %cl		# セクタ2

readloop:	
	movw	$0, %si		# リトライ・カウントを0にセット

retry:	# ディスク読み込み(リトライ機能あり)
	movb	$0x02, %ah	# ディスク読み込み
	movb	$1, %al		# 1セクタ分
	movw	$0, %bx
	movb	$0x00, %dl	# Aドライブ
	int	$0x13		# ディスクBIOS呼び出し
	jnc	next		# エラーがなければnextへ

	# リトライ回数が多ければerrorへ
	addw	$1, %si		# リトライ・カウントをインクリメント
	cmpw	$5, %si		# リトライ・カウントとリトライ回数(5)と比較
	jae	error		# リトライ回数以上なら、error

	# ドライブのリセット
	movb	$0x00, %ah
	movb	$0x00, %dl
	int	$0x13

	# リトライ
	jmp	retry

next:	# 次のセクタの読み込み
	# 読み込み先のアドレスを0x200進める
	movw	%es, %ax
	addw	$0x0020, %ax
	movw	%ax, %es
	# 18セクタまで繰り返し
	addb	$1, %cl
	cmpb	$18, %cl
	jbe	readloop	#  18 >= %cl だったらreadloopへ
	
	movb	$1, %cl
	addb	$1, %dh
	cmpb	$2, %dh
	jb	readloop	# 2 > %dh だったらreadloopへ

	movb	$0, %dh
	movb	$1, %ch
	cmpb	CYLS, %ch
	jb	readloop	# CYLS > %ch だったらreadloopへ
	
fin:	# 読み終わったけどとりあえずやることないので寝る
	hlt			# 何かあるまでCPUを停止させる
	jmp	fin		# 無限ループ

error:
	movw	$msg, %si
	
putloop: # 文字表示ループ。NUL文字が来るまで、ソフトウェア割り込み命令を使って、文字を表示していく。
	movb	(%si), %al
	addw	$1, %si
	cmpb	$0, %al		# NUL文字かどうか？
	je	fin		# NUL文字だったら、終了へ
	movb	$0x0e, %ah	# 1文字表示ファンクション
	movw	$15, %bx	# カラーコード
	int	$0x10		# ビデオBIOS呼び出し
	jmp	putloop

msg:	# メッセージ部分
	.byte	0x0a, 0x0a	# 改行を2つ
	.ascii	"load error"
	.byte 	0x0a		# 改行
	.byte 	0		# NUL文字

	.org	0x1fe, 0x00	# 0x1f0まで、0で埋める
	
	.byte	0x55, 0xaa	# ブート・シグニチャ(このマジックナンバーがないとマスターブートレコードとして有効にならない)
