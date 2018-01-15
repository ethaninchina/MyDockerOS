#12306余票查询工具
##调用方法：

	Usage:
	    tickets [-gdtkz] <from> <to> <date>
	Options:
	    -h,--help   显示帮助菜单
	    -g          高铁
	    -d          动车
	    -t          特快
	    -k          快速
	    -z          直达


比如想查9月2日从深圳---长沙`动车`和`特快`的余票：

python3 tickets.py -dg 深圳 长沙 2018-01-20
