.file 	"aomushi.s"
	
.code16
.text

	# 画面モードの切り替え
	movb	$0x13, %al	# VGAグラフィックス、320 x 200 x 8bitカラー
	movb	$0x00, %ah
	int	$0x10
	
fin:
	hlt
	jmp 	fin
	
