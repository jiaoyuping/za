# python.井字棋 2024.04.16
# by 焦玉平 and 耿宝存
def dis_board(board):
    # 显示出棋盘
    print("\t{0} | {1} | {2}".format(board[0], board[1], board[2]))
    print("\t_ | _ | _")
    print("\t{0} | {1} | {2}".format(board[3], board[4], board[5]))
    print("\t_ | _ | _")
    print("\t{0} | {1} | {2}".format(board[6], board[7], board[8]))

def _moves(board):
    # 寻求可落子的位置
    moves = []
    for i in range(9):
        if board[i] in list("123456789"):  # 遍历了棋盘的位置如果位置为1-9那么这个位置可以落子
            moves.append(i+1)
    return moves

def playermove(board):
    # 询问并确定玩家的选择落子位置，无效落子重复询问
    move = 10
    while move not in _moves(board):
        move = int(input("请选择落子位置(1-9):"))
    return move-1

def computermove(board, computerletter, playerletter):
    # 核心算法：计算computer的落子位置
    boardcopy = board.copy()

    # 规则一：如果玩家第一手第二手下对角，computer会输，防玩家一手
    while True:
        if (boardcopy[0] == boardcopy[8] == "x" and boardcopy[2] == "3"
                and boardcopy[6] == "7" and boardcopy[1] == "2"):
            return 1
        if (boardcopy[2] == boardcopy[6] == "x" and boardcopy[0] == "1"
                and boardcopy[8] == "9" and boardcopy[1] == "2"):
            return 1
        break

    # 规则二：判断如果某位置落子可以获胜，则选择这个位置
    for move in _moves(boardcopy):
        boardcopy[move-1] = computerletter
        if winner(boardcopy):
            return move-1
        boardcopy[move-1] = str(move)

    # 规则三：某个位置玩家下一步落子就可以获胜，则选择该位置
    for move in _moves(boardcopy):
        boardcopy[move-1] = playerletter
        if winner(boardcopy):
            return move-1
        boardcopy[move-1] = str(move)

    # 规则四：按照中心、角、边的选择空的位置
    for move in (5, 1, 3, 7, 9, 2, 4, 6, 8):
        if move in _moves(board):
            return move-1

def winner(board):
    # 判断所给棋子是否获胜
    to_win = {(0, 1, 2), (3, 4, 5), (6, 7, 8), (0, 3, 6), (1, 4, 7), (2, 5, 8), (0, 4, 8), (2, 4, 6)}
    for r in to_win:
        if board[r[0]] == board[r[1]] == board[r[2]]:
            return True
    return False

def Tie(board):
    # 判断是否平局
    for i in list("123456789"):
        if i in board:
            return False
    return True

def tic_tac_toe(playercore, computercore):
    # 井字棋
    board = list("123456789")
    playerletter = input("请选择棋子x(先走)或者o(后走)——(x|o)：")
    if playerletter in ("X", "x"):
        turn = "player"
        playerletter = "x"
        computerletter = "o"
    else:
        turn = "computer"
        computerletter = "x"
        playerletter = "o"
    print("{}先走！".format(turn))

    while True:
        dis_board(board)
        if turn == 'player':
            move = playermove(board)
            board[move] = playerletter
            if winner(board):
                dis_board(board)
                print("恭喜player获胜！")
                playercore = playercore + 1
                break
            else:
                turn = "computer"
        else:
            move = computermove(board, computerletter, playerletter)
            print("computer落子位置：", move+1)
            board[move] = computerletter
            if winner(board):
                dis_board(board)
                print("恭喜computer获胜！")
                computercore = computercore + 1
                break
            else:
                turn = "player"
        if Tie(board):
            dis_board(board)
            print('平局！')
            break

    print("player 对战 computer 比分是   ",playercore,":",computercore)
    if input('再玩一局?(yes|no)') == 'yes':
        tic_tac_toe(playercore, computercore)

if __name__ == '__main__':
    playercore = 0
    computercore = 0
    tic_tac_toe(playercore, computercore)