.model		small
.stack      

; constantes:		
CR		equ		0dh
LF		equ		0ah

; inicialização de variáveis:
.data 

; variáveis responsáveis pelo arquivo da matriz:
nome_arq		    db	'MAT.txt',0	    ; nome do arquivo txt com a matriz (default MAT.TXT)
FileBuffer		    db 10 dup (?)		; buffer para leitura do arquivo
arq_handle		    dw	0				; handler do arquivo MAT.TXT
arq_write_handle    dw	0				; handler do arquivo criado com WRITE
Matriz              dw 56 dup (0)       
MatrizUNDO          dw 56 dup (0)
numLinhas           dw 0
numColunas          dw 0
BufferTec	        db 100 dup (?)
BufferLinhaArq	    db 128 dup (?)
tamLinha 		    dw 0
i_linha             dw 0
ContadorLinha       dw 0
ContadorColuna      dw 0
BufferWRWORD        db 10 dup (0)
CharBuffer          db 0
TempNumBuffer       db 12 dup (0)
TempNumIdx          dw 0
formato_inv         dw 0               ; flag para indicar se o arquivo tem uma matriz em formato válido

; mensagens escritas na tela durante a execução:
MsgErroAbertura		db	"Erro na abertura do arquivo.", CR, LF, 0
MsgErroLeitura	    db	"Erro na leitura do arquivo.", CR, LF, 0
MsgErroFormato  	db	"Arquivo com formato invalido.", CR, LF, 0
MsgPedeOperacao     db  "Para operacao com parametros:", CR, LF, "  -> operacao param1", CR, LF, "  -> operacao param1, param 2", CR, LF, "Digite a operacao: ", CR, LF, 0
MsgCmdInvalido      db  "Operacao invalida.", CR, LF, 0 
MsgCRLF             db	 CR, LF, 0
MsgEspaco           db  ' ', 0
MsgPtVirgula        db  ';', 0
MsgSinal            db '-', 0

; comandos e parametros:
cmd_mul             db 'mul', 0
param_linha         dw 0
param_cte           dw 0
cmd_add             db 'add', 0
param_linha_org     dw 0
param_linha_dst     dw 0
cmd_write           db 'write', 0
param_nome          db 100 dup(0)
cmd_undo            db 'undo', 0

; variáveis usadas pela sprintf_w:
sw_n	            dw	0
sw_f	            db	0
sw_m	            dw	0

; ------------------------------------------------------------------------------------------
; programa principal:
.code
.startup                     ; ponto de entrada do programa

main:
	call	openFile         ; abre o arquivo MAT.TXT

le_linha_arquivo:
    call LeMatrizArquivo 
    cmp formato_inv, 1       ; ax = 0 -> arquivo da matriz com formato inválido
    je fim_programa

arquivo_ok:    
    mov  ax,numLinhas+1
    mov  ContadorColuna,ax 
    mov  ax,numLinhas
    mov  ContadorLinha,ax

menu_loop:
	call ImprimeMatriz       ; a cada iteração de operações, imprime a matriz resultante
    LEA BX, MsgPedeOperacao  ; aguarda operação
    CALL printf_s

	; le comando de operação digitado:
    MOV CX, 80               ; le até 79 caracteres + terminador
    LEA BX, BufferTec
    CALL ReadString          ; comando digitado vai para o buffer

	; aqui ocorre a verificação de qual comando foi digitado
    LEA SI, BufferTec
    LEA BX, cmd_mul            ; testa MUL
    CALL verifica_comando
    CMP AL, 1
    JE comando_mul             ; se for MUL, vai verificar os parametros (linha, cte)

    LEA SI, BufferTec
    LEA BX, cmd_add            ; testa ADD
    CALL verifica_comando
    CMP AL, 1
    JE comando_add             ; se for ADD, vai verificar os parametros (linhaORG, linhaDST)

	LEA SI, BufferTec
    LEA BX, cmd_write          ; testa WRITE
    CALL verifica_comando
    CMP AL, 1
    JE comando_write

	LEA  SI, BufferTec
    LEA  BX, cmd_undo          ; testa UNDO
    CALL verifica_comando
    CMP  AL, 1
    JE   comando_undo

	LEA  BX, MsgCmdInvalido    ; indica comando invalido
    CALL printf_s
    JMP  menu_loop             ; volta ao menu p aguardar novo comando valido

comando_add:
    LEA SI, BufferTec          ; buffertec = 'add linha_dst, linha_org'
    ADD SI, 4                  ; pula 'add ' para ler diretamente os parâmetros

    ; guarda o primeiro parametro (linha_dst):
    LEA  DI, TempNumBuffer

copia_linha_dst:
    MOV AL, [SI]
    CMP AL, 0
    JE fim_copia_linha_dst
    CMP AL, ','
    JE fim_copia_linha_dst
    MOV [DI], AL
    INC DI
    INC SI
    JMP copia_linha_dst

fim_copia_linha_dst:
    MOV BYTE PTR [DI], 0
    LEA BX, TempNumBuffer
    CALL atoi                   ; transforma o valor da linha original em decimal
    DEC AX                      ; interpreta o incio como 0 
    MOV param_linha_dst, AX

    ; avança posições da string até segundo parametro (linha_org):
pula_separador_add:
    MOV AL, [SI]
    CMP AL, 0
    JE fim_pulo_add
    CMP AL, ','
    JE inc_posicao_add
    CMP AL, ' '
    JE inc_posicao_add
    JMP fim_pulo_add

inc_posicao_add:
    INC SI
    JMP pula_separador_add

    ; guarda o segundo parametro: (linha_org)
fim_pulo_add:
    LEA DI, TempNumBuffer

copia_linha_org:
    MOV AL, [SI]
    CMP AL, 0
    JE fim_copia_linha_org
    CMP AL, ' '
    JE fim_copia_linha_org
    MOV [DI], AL
    INC DI
    INC SI
    JMP copia_linha_org

fim_copia_linha_org:
    MOV BYTE PTR [DI], 0
    LEA BX, TempNumBuffer
    CALL atoi
    DEC AX
    MOV param_linha_org, AX
    ; depois de guardar os parâmetros da operação, executa
    CALL executa_add

	JMP  menu_loop
; ---------------------------------
comando_mul:
	LEA  SI, BufferTec            ; buffertec = 'mul linha, constante'
    ADD  SI, 4                    ; pula 'mul ' para ler diretamente os parâmetros
    
    ; guarda o primeiro parametro (linha da matriz):
    LEA  DI, TempNumBuffer

copia_linha:
    MOV AL, [SI]
    CMP AL, 0
    JE fim_copia_linha
    CMP AL, ','
    JE fim_copia_linha
    MOV [DI], AL
    INC DI
    INC SI
    JMP copia_linha

fim_copia_linha:
    MOV BYTE PTR [DI], 0
    LEA BX, TempNumBuffer
    CALL atoi
    DEC AX
    MOV param_linha, AX

    ; avança posições da string até segundo parametro (constante):
pula_separador:
    MOV AL, [SI]
    CMP AL, 0
    JE fim_pulo
    CMP AL, ','
    JE inc_posicao
    CMP AL, ' '
    JE inc_posicao
    JMP fim_pulo

inc_posicao:
    INC SI
    JMP pula_separador

    ; guarda o segundo parametro:
fim_pulo:
    LEA DI, TempNumBuffer

copia_cte:
    MOV AL, [SI]
    CMP AL, 0
    JE fim_copia_cte
    CMP AL, ' '
    JE fim_copia_cte
    MOV [DI], AL
    INC DI
    INC SI
    JMP copia_cte

fim_copia_cte:
    MOV BYTE PTR [DI], 0
    LEA BX, TempNumBuffer
    CALL atoi
    MOV param_cte, AX

    ; depois de guardar os parametros da operação, executa:
    CALL executa_mul             

	JMP  menu_loop
; -----------------------------
comando_undo:
    CALL executa_undo
	JMP  menu_loop

; -----------------------------
comando_write:
    LEA SI, BufferTec            ; buffertec = 'write nome'
    ADD SI, 6                    ; pula 'write ' para ler o parâmetro nome
    LEA DI, param_nome           ; copia o nome digitado para param_nome
copia_nome:
    MOV AL, [SI]
    CMP AL, 0
    JE fim_copia_nome
    MOV [DI], AL
    INC DI
    INC SI
    JMP copia_nome
fim_copia_nome:
    MOV BYTE PTR [DI], 0
    CALL executa_write          
	JMP  menu_loop

fim_programa:
	.exit
; --------------------------------------------------------------------------------------------------------------------

; a partir daqui, estão as rotinas auxiliares utilizadas pelo programa principal:

; função para verificar se o comando digitado é um comando válido (add, mul, undo ou write):
verifica_comando proc 
	lea si, BufferTec
	mov di, bx

cmp_loop:
    mov al, [di]        ; caractere do comando (referência)
    cmp al, 0
    je fim_cmd          ; acabou a palavra de referência

    mov dl, [si]        ; caractere do input do usuário
    cmp dl, 0
    je erro_comp        ; input terminou antes do comando referência = inválido

    cmp al, dl
    jne erro_comp       ; comando != referência = inválido

    inc di
    inc si
    jmp cmp_loop

fim_cmd:
    ; próximo caractere no input deve ser separador (ou fim)
    mov dl, [si]
    cmp dl, 0
    je cmp_ok
    cmp dl, ' '
    je cmp_ok
    cmp dl, ','
    je cmp_ok
    cmp dl, 9         
    je cmp_ok
    cmp dl, CR
    je cmp_ok
    cmp dl, LF
    je cmp_ok

    jmp erro_comp

cmp_ok:
    mov al, 1
    jmp fim_comp

erro_comp:
    xor al, al

fim_comp:
    ret
verifica_comando endp

; função printf_s - imprime string na tela:
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
ps_1:
	ret
printf_s	endp


; função ReadString - le string digitada
ReadString PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    XOR DX, DX        ; contador
RS_loop:
    MOV AH, 01h
    INT 21h           ; AL = char 
    CMP AL, 13
    JE RS_end
    CMP AL, 8
    JE RS_backspace
    CMP AL, ' '
    JB RS_loop
    CMP DX, CX
    JAE RS_loop

    MOV [BX], AL
    INC BX
    INC DX
    JMP RS_loop

RS_backspace:
    CMP DX, 0
    JE RS_loop
    DEC BX
    DEC DX
    ; apaga na tela: BS, espaço, BS
    MOV DL, 8
    MOV AH, 02h
    INT 21h
    MOV DL, ' '
    MOV AH, 02h
    INT 21h
    MOV DL, 8
    MOV AH, 02h
    INT 21h
    JMP RS_loop

RS_end:
    MOV BYTE PTR [BX], 0

    POP DX
    POP CX
    POP BX
    POP AX
    RET
ReadString ENDP


; converte dígito ascii para núnmero inteiro hexadecimal:
atoi	proc near
    push bx
    push cx
    push dx
    push si

    xor ax, ax      
    xor si, si       ; flag de num negativo 

    cmp byte ptr [bx], '-'  
    jne atoi_loop    ; verifica se o numero é negativo
    inc bx           ; ignora o sinal de menos
    mov si, 1        ; liga flag de negativo
	
    atoi_loop:       ; le toda a string
    mov cl, [bx]
    cmp cl, 0       
    je  atoi_end

    cmp cl, '0'       ; ignora se não for dígito
    jb  atoi_next
    cmp cl, '9'
    ja  atoi_next

    sub cl, '0'     ; conversão de ascii p inteiro
    mov ch, 0
    
    mov dx, 10
    mul dx          ; AX = AX * 10
    add ax, cx      ; AX = AX + NovoDigito

atoi_next:
    inc bx
    jmp atoi_loop

atoi_end:
    cmp si, 1       ; se o numero era negativo
    jne atoi_exit
    neg ax          ; inverte o numero (c2) e finaliza

atoi_exit:
    pop si
    pop dx
    pop cx
    pop bx
    ret

atoi	endp
; -------------------------------------------------------------------------

; aqui estão as funções que executam as operações MUL, ADD, UNDO e WRITE

; função MUL - multiplica linha da matriz por constante:
executa_mul     proc    near
    push ax
    push bx
    push cx
    push dx
    push di
    push si

    mov  di, 0
    mov  cx, 56
    mov  ax, 0
copia:
    mov  ax, Matriz[di]
    mov  MatrizUNDO[di], ax
    add  di, 2  
    dec  cx
    cmp  cx, 0
    jnz  copia

fim_copia:
    mov  ax, param_linha
    mov  cx, numColunas
    mov  bx, param_cte
    mul  numColunas
    shl  ax, 1
    mov  di, ax
mul_linha:
    mov  ax,  Matriz[di]    ; guarda valor inicial da linha
    mul  param_cte          ; multiplica por param_cte
    mov  Matriz[di], ax     ; guarda resultado
    add  di, 2              ; avança para próxima coluna
    dec  cx
    cmp  cx, 0
    jnz  mul_linha

fim_mul_linha:               ; finaliza e guarda o contexto
    pop  si
    pop  di
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret
executa_mul     endp


; função UNDO - ctrl z na última operação realizada
executa_undo proc near
    mov di, 0
    mov cx, 56
    mov ax, 0 
desfaz:
    mov ax, MatrizUNDO[di]
    mov Matriz[di], ax
    add di, 2
    dec cx
    cmp cx, 0
    jnz desfaz
    ret

executa_undo endp


; função ADD - linha_dst = linha_org + linha_dst
executa_add  proc near
    push  ax
    push  bx
    push  cx
    push  dx
    push  di
    push  si

    mov  di, 0
    mov  cx, 56
    mov  ax, 0
copia_soma:
    mov  ax, Matriz[di]
    mov  MatrizUNDO[di], ax
    add  di, 2
    dec  cx
    cmp  cx, 0
    jnz  copia_soma

fim_copia_soma:
    mov ax, param_linha_org   
    mov cx, numColunas

    mul numColunas
    shl ax, 1
    mov si, ax

    mov ax, param_linha_dst
    mul numColunas
    shl ax, 1
    mov di, ax

soma_linha:
    mov dx,  Matriz[si]       ; guarda valor de linha_org
    add dx,  Matriz[di]       ; soma com linha_dst
    mov Matriz[di], dx        ; guarda o resultado
    add si, 2                 ; vai para proxima coluna de linha_org
    add di, 2                 ; vai para proxima coluna de linha_dst
    dec cx                    ; continua até somar todas as colunas das duas linhas
    cmp cx, 0
    jnz soma_linha

fim_soma_linha:
    pop  si
    pop  di
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret
executa_add      endp

; função WRITE - grava a matriz atual em um arquivo de saída:
executa_write proc near
    call cria_arquivo
    call monta_write
    mov	 bx, arq_write_handle		
	mov	 ah, 3eh             ; fecha o arquivo criado
	int	 21h
    ret
executa_write endp

; função cria_arquivo - cria arquivo 'param_nome.txt'
cria_arquivo    proc near 
    mov  cx, 0             
    lea  dx, param_nome        ; arquivo deve ser criado com o nome passado por parâmetro
    mov  ah, 3ch               ; função para criar o arquivo
    int  21h
    jnc  arquivo_criado        ; arquivo foi criado sem erros

    lea  bx, MsgErroAbertura   ; c = 1, erro na criação do novo arquivo
    call printf_s
    ret 
arquivo_criado:
    mov  arq_write_handle, ax  ; guarda handle para escrever arquivo corretamente depois
    ret
cria_arquivo    endp

; função que guarda a matriz para depois escrever no arquivo 'param_nome.txt':
monta_write	proc    near
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov  cx, 0                   ; cx = contador de linhas
    mov  ah, 40h                 ; função para escrever no arquivo (utilizada depois)

imprime_linha_arquivo:
    mov  ax, numLinhas
    cmp  cx, ax
    jnl  fim_impressao_arquivo   ; linha >= num_linhas = impressão terminou
    mov  dx, 0                   ; DX = contador de colunas
imprime_coluna_arquivo:
    mov  ax, numColunas
    cmp  dx, ax
    jnl  prox_linha_write
    ; end = (linha * numColunas + coluna) * 2
    push dx                  ; salva dx (cont de colunas) na pilha
    push cx                  
    mov  ax, cx              
    mul  numColunas          ; AX = linha * colunas
    pop  cx
    pop  bx                  ; contador de coluna volta para dx
    add  ax, bx 
    shl  ax, 1               ; soma a coluna: AX = AX + Col
    lea  si, Matriz         
    add  si, ax              ; soma o deslocamento calculado no começo da matriz
    mov  ax, [si]            
    push bx
    push cx                
    cmp  ax,0
    jg   positivo_write
    push ax
    lea  bx, MsgSinal
    call escreve_arq_write
    pop  ax
    neg  ax
positivo_write:
    ; converte ax para string no BufferWRWORD
    lea  bx, BufferWRWORD
    call sprintf_w       

    ; escreve o buffer no arquivo
    lea  bx, BufferWRWORD
    call escreve_arq_write
    pop  cx              
    pop  dx               

    ; se nao for a ultima coluna = insere ';'
    mov  ax, numColunas
    dec  ax
    cmp  dx, ax               ; compara coluna atual com última
    jae  sem_pt_virgula       ; se for a última, não coloca ';'
    lea  bx, MsgPtVirgula
    call escreve_arq_write

sem_pt_virgula:
    inc  dx                    ; avança para proxima coluna
    jmp  imprime_coluna_arquivo

prox_linha_write:
    ; fim de linha = insere CRLF
    lea  bx, MsgCRLF
    call escreve_arq_write
    inc  cx                    ; avança pra proxima linha
    jmp  imprime_linha_arquivo ; repete até terminar de escrever a matriz

fim_impressao_arquivo:
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret
monta_write    endp


; função que escreve a matriz já pronta no arquivo 'param_nome.txt':
escreve_arq_write proc near
    push ax
    push cx
    push dx
    push si
    
    ; calcula tamanho da string a ser escrita
    mov  si, bx
tamanho:
    cmp  byte ptr [si], 0
    je   escreve_write
    inc  si
    jmp  tamanho
    
escreve_write:
    sub  si, bx                ; si = tamanho da string
    mov  cx, si                ; cx = bytes para escrever
    
    cmp  cx, 0
    je   fim_escrita           ; terminou a ecrita

    mov  dx, bx                ; dx aponta para o buffer
    mov  bx, arq_write_handle  ; utiliza o handle do arquivo para escrever 
    mov  ah, 40h               ; função para escrita em arquivos
    int  21h
    
fim_escrita:
    pop  si
    pop  dx
    pop  cx
    pop  ax
    ret
escreve_arq_write endp

; abre o arquivo MAT.TXT 
openFile proc near 
	mov  al, 0
	lea  dx, nome_arq
	mov	 ah, 3dh
	int	 21h
	jnc	 Continua
	
	lea	 bx, MsgErroAbertura
	call printf_s
	
	.exit 1
	
Continua:
	mov	 arq_handle, ax		; salva handle do arquivo
    ret
openFile endp


; le MAT.TXT byte a byte 
LeMatrizArquivo proc near
    mov  ContadorLinha, 0
    mov  ContadorColuna, 0
    mov  TempNumIdx, 0
    mov  numColunas, 0

le_byte:
    mov  ah, 3Fh
    mov bx, arq_handle
    mov cx, 1
    lea dx, CharBuffer
    int 21h
    
    jc  fim_leitura
    cmp ax, 0
    je  fim_leitura_eof

    mov al, CharBuffer

    ; verifica se está lendo digito ou algum caractere diferente:
    cmp al, '0'
    jb  verifica_caracteres    ; se for caractere -> vai verificar se é válido
    cmp al, '9'
    ja  verifica_caracteres
    
    ; guarda o dígito lido
    lea  bx, TempNumBuffer
    add  bx, TempNumIdx
    mov  [bx], al
    inc  TempNumIdx
    jmp  le_byte

verifica_caracteres:
    cmp  al, '-'             ; sinal = válido
    je   eh_sinal

    cmp  al, ';'             ; separador = válido, indica fim do dígito
    je   fim_nmr

    cmp  al, 0Dh             ; CR = válido, segue a leitura da matriz
    je   le_byte         
    
    cmp  al, 0Ah             ; LF = válido (enter), pula p próxima linha
    je   fim_linha    

    jmp  erro_formato        ; qualquer outro caractere = inválido

eh_sinal:
    lea  bx, TempNumBuffer
    add  bx, TempNumIdx
    mov  [bx], al
    inc  TempNumIdx
    jmp  le_byte

fim_nmr:
    call SalvarNumeroNaMatriz
    inc  ContadorColuna
    mov  TempNumIdx, 0
    jmp  le_byte

fim_linha:
    ; se sobrou numero no buffer antes do enter, salva
    cmp  TempNumIdx, 0
    je   pula_salvar
    call SalvarNumeroNaMatriz
    
pula_salvar:
    mov ax, ContadorColuna
    inc ax

    cmp ContadorLinha, 0
    jne compara_colunas
    mov numColunas, ax
    jmp prox_linha_setup
compara_colunas:
    cmp ax, numColunas
    jne erro_formato

prox_linha_setup:
    inc ContadorLinha
    mov ContadorColuna, 0
    mov TempNumIdx, 0
    jmp le_byte

fim_leitura_eof:
    cmp  TempNumIdx, 0
    je   salva_qnt_linhas
    call SalvarNumeroNaMatriz
    mov ax, ContadorColuna
    inc ax
    cmp ContadorLinha, 0
    jne compara_colunas_eof
    mov numColunas, ax
    jmp inc_final_linha
compara_colunas_eof:
    cmp ax, numColunas
    jne erro_formato

inc_final_linha:
    inc ContadorLinha

salva_qnt_linhas:
    mov ax, ContadorLinha
    mov numLinhas, ax
    jmp fim_leitura

erro_formato:
    mov formato_inv, 1
    lea bx, MsgErroFormato
    call printf_s

fim_leitura:
    ret
LeMatrizArquivo endp

SalvarNumeroNaMatriz proc near
    lea     bx, TempNumBuffer
    add     bx, TempNumIdx
    mov     byte ptr [bx], 0    ; finaliza a string com 0
    lea     bx, TempNumBuffer
    call    atoi                ; converte string pra inteiro
    mov     ax, ContadorLinha
    cmp     ax, 0
    je      salva_linha_1
    mov     ax, ContadorLinha   ; se nao é a primeira linha = usa num de colunas
    mul     numColunas          ; AX = numLInhas * numColunas
    add     ax, ContadorColuna 
    shl     ax, 1          
    jmp     guarda

salva_linha_1:
    mov     ax, ContadorColuna
    shl     ax, 1

guarda:
    lea     di, Matriz
    add     di, ax
    lea     bx, TempNumBuffer
    add     bx, TempNumIdx
    mov     byte ptr [bx], 0
    lea     bx, TempNumBuffer
    call    atoi
    
    ; converte
    lea     bx, TempNumBuffer
    add     bx, TempNumIdx
    mov     byte ptr [bx], 0 
    lea     bx, TempNumBuffer
    call    atoi
    push    ax              ; salva valor decimal
    mov     ax, ContadorLinha
    cmp     ax, 0
    je      off_lin_0
    mov     ax, ContadorLinha
    mul     numColunas
    add     ax, ContadorColuna
    jmp     calcula_off
    
off_lin_0:
    mov     ax, ContadorColuna
    
calcula_off:
    shl     ax, 1           ; * 2
    lea     di, Matriz
    add     di, ax
    pop     ax              ; guarda valor
    mov     [di], ax        ; salva na memoria
    ret
SalvarNumeroNaMatriz endp

; converte inteiro em hexadecimal para dígito decimal (ascii):
HexToDecAscii  proc near

    mov  cx,0                           ;N = 0;
H2DA_2:
     or  ax,ax                          ;while (A!=0) {
    jnz  H2DA_0
    or   cx,cx
    jnz  H2DA_1

H2DA_0:
    mov  dx,0                        ;A = A / 10
    mov  si,10                       ;dl = A % 10 + '0'
    div  si
    add  dl,'0'
    mov  si,cx                       ;S[N] = dl
    mov  [bx+si],dl        
    inc  cx                          ;++N
    jmp  H2DA_2

H2DA_1:
    mov  si,cx                       ;S[N] = '\0'
    mov  byte ptr[bx+si],0
    mov  si,bx                       ;i = 0
    add  bx,cx                       ;j = N-1
    dec  bx
    sar  cx,1                        ;N = N / 2

H2DA_4:
    or   cx,cx                        ;while (N!=0) {
    jz   H2DA_3
    mov  al,[si]                     ;S[i] <-> S[j]
    mov  ah,[bx]
    mov  [si],ah
    mov  [bx],al
    dec  cx                          ;        --N
    inc  si                          ;        ++i
    dec  bx                          ;        --j
    jmp  H2DA_4

H2DA_3:
    ret
HexToDecAscii  endp

; função que imprime digito com sinal, se for negativo:
imprime_c_sinal        proc        near
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    xor cx, cx
    cmp ax, 0
    jge prepara_conversao
    neg ax
    mov cx, 1                     ; 0 = positivo, 1 = negativo
prepara_conversao:
    push cx

    lea bx, BufferWRWORD
    call HexToDecAscii            ; converte o número (que agora é positivo) para texto
    
    pop  si

    xor  cx, cx                ; cx = contador de tamanho
    lea  bx, BufferWRWORD

mede_tamanho_loop:
    mov  di, cx
    cmp  byte ptr [bx + di], 0 ; verifica se acabou a string
    je   mede_tamanho_fim
    inc  cx
    jmp  mede_tamanho_loop

mede_tamanho_fim:
    cmp  si, 1
    jne  calcula_espacos
    inc  cx

calcula_espacos:
    mov  ax, 8
    sub  ax, cx
    cmp  ax, 0
    mov  cx, ax

imprime_espacos:
    mov  dl, MsgEspaco
    mov  ah, 2
    int  21h
    loop imprime_espacos

imprime_sinal:
    ; imprime '-' se for negativo
    cmp si, 1
    jne imprime_nmr
    mov dl, MsgSinal
    mov ah, 2
    int 21h

imprime_nmr:
    lea bx, BufferWRWORD
    call printf_s    ; imprime os digitos na tela

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
imprime_c_sinal        endp

; função sprintf_w:
sprintf_w proc near
;void sprintf_w(char *string, WORD n) {
	mov	sw_n,ax

;	k=5;
	mov	cx,5
	
;	m=10000;
	mov	sw_m,10000
	
;	f=0;
	mov	sw_f,0
	
;	do {
sw_do:
;		quociente = n / m : resto = n % m;	// Usar instrução DIV
	mov	dx,0
	mov	ax,sw_n
	div	sw_m
	
;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
	cmp	al,0
	jne	sw_store
	cmp	sw_f,0
	je	sw_continue
sw_store:
	add	al,'0'
	mov	[bx],al
	inc	bx
	mov		sw_f,1
sw_continue:
;		n = resto;
	mov	sw_n,dx
;		m = m/10;
	mov	dx,0
	mov	ax,sw_m
	mov	bp,10
	div	bp
	mov	sw_m,ax
;		--k;
	dec	cx
;	} while(k);
	cmp	cx,0
	jnz	sw_do
;	if (!f)
;		*string++ = '0';
	cmp	sw_f,0
	jnz	sw_continua2
	mov	[bx],'0'
	inc	bx
sw_continua2:
;	*string = '\0';
	mov	byte ptr[bx],0	
;}
	ret
sprintf_w	endp


; imprime matriz de acordo com a especificação - num 6 espaços + 2 espaços separadores
ImprimeMatriz proc near
    lea  bx, MsgCRLF
    call printf_s

    mov  cx, 0                  ; cx = contador de linhas
imprime_linha:
    mov  ax, numLinhas
    cmp  cx, ax
    jae  fim_impressao          ; linha >= numLinhas, acabou a matriz

    mov  dx, 0                  ; dx = contador de coluna
imprime_coluna:
    mov  ax, numColunas
    cmp  dx, ax
    jae  prox_linha             ; coluna >= numColunas, avança para próxima linha

    ; end = (linha * numColunas + coluna) * 2
    push    dx                  ; salva dx
    mov     ax, cx              
    mul     numColunas          ; ax = linha * numColunas 
    pop     dx                  
    add     ax, dx              ; ax = ax + col
    shl     ax, 1               ; *2 (16 bits)
    lea     si, Matriz          
    add     si, ax              ; soma deslocamento com o inicio da matriz
    mov     ax, [si]            
    push    cx                 
    push    dx

    call    imprime_c_sinal     ; imprime valor em ax
    pop     dx                
    pop     cx

    inc     dx                  ; avança para proxima coluna
    jmp     imprime_coluna

prox_linha:
    lea     bx, MsgCRLF         ; enter - proxima linha na tela
    call    printf_s
    inc     cx                  ; le proxima linha da matriz
    jmp     imprime_linha
fim_impressao:
    ret
ImprimeMatriz endp

		end
