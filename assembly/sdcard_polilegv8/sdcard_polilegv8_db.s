; código do controlador do cartão SD
; Feito por Théo Amaral, 2026

; controlador: miso - mosi - cs - sck
; organização do cartão SD:
; [0..1] = tamanho da sequência (MSB primeiro)
; [2..5] = contador do bpm (MSB primeiro)
; [6..511] = notas musicais


.data
    0x1000              ; endereco do controlador do cartao
    0x0001              ; constante 1 / sck = 1
    0x0002              ; cs = 1
    0x0004              ; mosi = 1
    0xE                 ; zerar sck
    0xD                 ; zerar cs
    0xB                 ; zerar mosi
    0xF80               ; endereço inicial da stack
    #17                 ; contagem do sck
    #10                 ; constante de 10 pulsos pra inicializacao
    0x80                ; máscara do bit 8
    0xFF                ; inicialização do cartão, byte dummy
    #8                  ; contagem de 8 bits do spi_xfer
    0x400000000095      ; CMD0
    #10                 ; timeout
    0x48000001AA87      ; CMD8
    0xAA                ; comparação do byte menos significativo da resposta do CMD8
    0x770000000001      ; CMD55
    0x694000000001      ; ACMD41
    0x5100000000FF      ; CMD17 bloco 0
    0xFE                ; resposta correta do CMD17
    #512                ; constante 512 pra leitura de bloco
    0x200               ; endereço dos bytes do bloco do cartão
    0x206               ; endereço inicial das notas

.text
main:

    ldur x20, [x31, #0]     ; x20 -> endereco do controlador do cartao
    ldur x21, [x31, #1]     ; x21 -> constante 1
    ldur x22, [x31, #2]     ; x22 -> cs = 1
    ldur x23, [x31, #3]     ; x23 -> mosi = 1
    ldur x24, [x31, #4]     ; x24 -> zerar sck
    ldur x25, [x31, #5]     ; x25 -> zerar cs
    ldur x26, [x31, #6]     ; x26 -> zerar mosi
    ldur x27, [x31, #22]    ; x27 -> ponteiro do bloco do cartão
    ldur x28, [x31, #23]    ; x28 -> ponteiro do endereço inicial das notas
    ldur x29, [x31, #7]     ; x29 -> stack pointer

inicializar_cartao:
    add x0, x22, x31        ; CS em alto no x0
    orr x0, x0, x23         ; MOSI em alto no x0
    and x0, x0, x24         ; SCK em baixo no x0
    stur x0, [x20, #0]      ; guarda x0 no controlador

    ldur x1, [x31, #11]     ; guarda em x1 o byte dummy
    ldur x2, [x31, #9]      ; guarda em x2 a contagem de 10 bytes dummy
loop_dummy_bytes:
    cbz x2, manda_cmd0

    and x0, x1, x1
    bl spi_xfer
    sub x2, x2, x21
    b loop_dummy_bytes

manda_cmd0:
    ldur x0, [x20, #0]      ; carrega o controlador no x0
    and x0, x0, x25         ; zera o CS
    stur x0, [x20, #0]      ; devolve pro controlador o x0

    ldur x0, [x31, #13]     ; carrega o valor do CMD0 no x0
    bl send_cmd             ; manda o CMD0, espera resposta 0x01
    sub x0, x0, x21         ; subtrai 1 do x0
    cbz x0, manda_cmd8      ; resposta valida? manda_cmd8
    b inicializar_cartao    ; volta pra inicializar_cartao caso contrario

manda_cmd8:
    ldur x0, [x31, #15]             ; carrega CMD8 no x0
    bl send_cmd                     ; manda o CMD8, espera resposta 0x01
    sub x0, x0, x21                 ; subtrai 1 do x0
    cbz x0, cmd8_le_resposta        ; resposta valida? manda_cmd8
    b erro_inicializando_cartao     ; vai pra erro_inicializando_cartao caso contrário

cmd8_le_resposta:
    ldur x0, [x31, #11]     ; carrega x0 com byte dummy
    bl spi_xfer             ; manda x0 pro cartão, vê resposta
    and x1, x0, x0          ; copia a resposta 1 pro x1
    
    ldur x0, [x31, #11]     ; carrega x0 com byte dummy
    bl spi_xfer             ; manda x0 pro cartão, vê resposta
    and x2, x0, x0          ; copia a resposta 2 pro x2

    ldur x0, [x31, #11]     ; carrega x0 com byte dummy
    bl spi_xfer             ; manda x0 pro cartão, vê resposta
    and x3, x0, x0          ; copia a resposta 3 pro x3

    ldur x0, [x31, #11]     ; carrega x0 com byte dummy
    bl spi_xfer             ; manda x0 pro cartão, vê resposta
    and x4, x0, x0          ; copia a resposta 4 pro x4

    and x3, x3, x21             ; mascara o lsb pra ver se é compatível com 3.3V
    sub x3, x3, x21             ; compara x3 com 0x1
    ldur x5, [x31, #16]         ; carrega o comparador no x5
    sub x4, x4, x5              ; subtrai o lsByte do comparador
    cbz x3, cmd8_confere_lsbyte ; resposta 3 válida? vê se resposta 4 é também
    b erro_inicializando_cartao ; senão, vai pra erro_inicializando_cartao

cmd8_confere_lsbyte:
    cbz x4, manda_cmd55         ; ve se a resposta 4 também é válida, se for, manda_cmd55
    b erro_inicializando_cartao ; erro caso contrário

manda_cmd55:
    ldur x0, [x31, #17]         ; carrega CMD55 no x0
    bl send_cmd                 ; manda CMD55 pro cartão
    ldur x0, [x31, #18]         ; carrega ACMD41 no x0
    bl send_cmd                 ; manda ACMD41 pro cartão

    cbz x0, le_cartao           ; o cartão está inicializado corretamente, vai pra le_cartao
    b manda_cmd55               ; volta pra mandar cmd55 de novo, até o cartão ficar pronto

erro_inicializando_cartao:
    ldur x0, [x31, #11]     ; carrega constante 0xFF no x0
    lsl x0, x0, #56         ; coloca 0xFF no byte mais significativo do x0
    stur x0, [x20, #1]      ; carrega o x0 na GPIO
erro_loop:
    b erro_loop

le_cartao:
    ldur x0, [x31, #19]         ; carrega x0 com o CMD17
    bl send_cmd                 ; manda o CMD17
    cbz x0, le_cartao_espera_FE ; se receber o correto, espera o cartão mandar 0xFE
    b le_cartao                 ; senão, volta pra mandar o CMD17

le_cartao_espera_FE:
    ldur x1, [x31, #20]         ; carrega o 0xFE no x1
    ldur x2, [x31, #11]         ; carrega o 0xFF no x2

le_cartao_espera_FE_loop:
    and x0, x2, x2              ; copia x2 em x0 (0xFF)
    bl spi_xfer                 ; manda 0xFF pro cartão, dummy byte
    sub x0, x0, x1              ; compara resposta com 0xFE
    cbz x0, le_cartao_le_bloco  ; le o bloco se a resposta estiver correta
    b le_cartao_espera_FE_loop  ; espera denovo se não tiver resposta correta

le_cartao_le_bloco:
    ldur x1, [x31, #21]         ; carrega o contador de 512 no x1
    and x2, x27, x27            ; copia o endereço do bloco na memória em x2
    ldur x3, [x31, #11]         ; carrega 0xFF no x3

le_cartao_le_bloco_loop:
    cbz x1, le_cartao_recebe_crc ; recebe os 2 byres de CRC do cartão, se a contagem acabar

    and x0, x3, x3              ; copia o valor do x3 em x0 (dummy byte)
    bl spi_xfer                 ; le os bytes do bloco
    stur x0, [x2, #0]           ; guarda o valor do byte atual no endereço do ponteiro da memória
    add x2, x2, x21             ; adiciona 1 no ponteiro
    sub x1, x1, x21             ; subtrai um no contador
    b le_cartao_le_bloco_loop   ; volta pro início do loop

le_cartao_recebe_crc:
    and x0, x3, x3              ; carrega dummy byte no x0
    bl spi_xfer                 ; pega o CRC byte 1
    and x0, x3, x3              ; carrega dummy byte no x0
    bl spi_xfer                 ; pega o CRC byte 2

    ldur x0, [x20, #0]          ; carrega o valor atual do controlador
    orr x0, x0, x22             ; sobe o CS
    stur x0, [x20, #0]          ; devolve o valor do controlador com o CS em alto

toca_musica_inicializacao:
    ; carrega o número de notas no x2
    and x1, x27, x27            ; carrega o ponteiro no x1
    ldur x0, [x1, #5]
    stur x0, [x20, #1]

loop:
    b loop


; SUBROTINAS

send_cmd: ; subrotina para mandar o comando que está em x0 para o cartão SD
          ; retorna: resposta em x0 (válida ou não)
          ; SOBRESCREVE: x0

    stur x30, [x29, #0]     ; guarda o ponteiro de retorno na stack
    add x29, x29, x21       ; adiciona um no stack pointer
    stur x1, [x29, #0]      ; guarda valor de x1 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer
    stur x2, [x29, #0]      ; guarda valor de x2 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer
    stur x3, [x29, #0]      ; guarda valor de x3 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer
    stur x4, [x29, #0]      ; guarda valor de x4 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer

    and x1, x0, x0          ; coloca o comando no x1

    lsr x0, x1, #40         ; pega o comando[47:40]
    bl spi_xfer             ; manda x0

    lsr x0, x1, #32         ; pega o comando[39:32]
    bl spi_xfer             ; manda x0

    lsr x0, x1, #24         ; pega o comando[31:24]
    bl spi_xfer             ; manda x0

    lsr x0, x1, #16         ; pega o comando[23:16]
    bl spi_xfer             ; manda x0

    lsr x0, x1, #8          ; pega o comando[15:8]
    bl spi_xfer             ; manda x0

    lsr x0, x1, #0          ; pega o comando[7:0]
    bl spi_xfer             ; manda x0

    ldur x1, [x31, #14]     ; carrega o timeout
    ldur x2, [x31, #11]     ; carrega 0xFF pra dummy byte
    ldur x3, [x31, #10]     ; carrega a mascara do bit 8 no x3

send_cmd_timeout_loop:
    cbz x1, send_cmd_end
    
    and x0, x2, x2          ; copia x2 pra x0
    bl spi_xfer             ; le resposta do cartão
    and x4, x3, x0          ; mascara o bit 8
    cbz x4, send_cmd_end    ; resposta valida? vai pra send_cmd_end
    sub x1, x1, x21         ; subtrai 1 no contador de timeout
    b send_cmd_timeout_loop ; volta pro loop

send_cmd_end:
    
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x4, [x29, #0]      ; pega o valor do x4 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x3, [x29, #0]      ; pega o valor do x3 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x2, [x29, #0]      ; pega o valor do x2 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x1, [x29, #0]      ; pega o valor do x1 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x30, [x29, #0]     ; pega o valor do ponteiro de retorno da stack

    br x30                  ; retorna da subrotina
; FIM DA SEND_CMD


spi_xfer: ; subrotina pra mandar o byte menos significativo do x0 pro spi, sem alterar o CS (supõe que o clock está em nível BAIXO)
          ; retorna: x0 com o valor do MISO
          ; SOBRESCREVE: x0

    stur x30, [x29, #0]     ; guarda o ponteiro de retorno na stack
    add x29, x29, x21       ; adiciona um no stack pointer

    stur x1, [x29, #0]      ; guarda valor de x1 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer
    stur x2, [x29, #0]      ; guarda valor do x2 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer
    stur x3, [x29, #0]      ; guarda valor do x3 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer
    stur x4, [x29, #0]      ; guarda valor do x4 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer

    ldur x1, [x31, #10]     ; carrega a máscara do MSB no x1
    ldur x4, [x31, #12]     ; carrega a contagem de 8 no x4

spi_xfer_loop_write:
    cbz x4, spi_xfer_continue ; x4 = 0? spi_xfer_continue

    ldur x3, [x20, #0]      ; carrega os bits do controlador no x3
    and x3, x3, x26         ; mascara o bit do MOSI

    and x2, x0, x1          ; mascara o MSB do byte a escrever e guarda em x2
    lsl x0, x0, #1          ; desloca um bit pra esquerda no x0, pra guardar o próximo bit do miso
    lsr x2, x2, #5          ; desloca o MSB pra posição do MOSI e guarda em x2
    orr x2, x3, x2          ; sobrescreve x2 com o valor correto pro controlador
    stur x2, [x20, #0]      ; carrega no controlador

    bl toggle_sck           ; flipa o clock pra 1
    ldur x2, [x20, #0]      ; lê os bits de controle e guarda em x2
    lsr x2, x2, #3          ; desloca o MISO pra posição certa
    orr x0, x0, x2          ; guarda em x0 o bit do MISO atual
    bl toggle_sck           ; flipa o clock de volta para 0

    sub x4, x4, x21         ; subtrai um na contagem do x4
    b spi_xfer_loop_write   ; volta pro loop

spi_xfer_continue:

    ldur x1, [x31, #11]     ; carrega constante 0xFF no x1
    and x0, x0, x1          ; mascara o primeiro byte no x0

    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x4, [x29, #0]      ; pega o valor do x5 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x3, [x29, #0]      ; pega o valor do x4 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x2, [x29, #0]      ; pega o valor do x3 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x1, [x29, #0]      ; pega o valor do x2 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x30, [x29, #0]     ; pega o valor do ponteiro de retorno da stack

    br x30                  ; retorna da subrotina
; FIM DA SPI_XFER


toggle_sck:  ; subrotina pra flipar o sck

    ; salvar os registradores na stack
    stur x0, [x29, #0]      ; guarda valor do x0 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer
    stur x1, [x29, #0]      ; guarda valor do x1 na stack
    add x29, x29, x21       ; adiciona 1 no stack pointer

    ; pegar valor atual do clock e flipar
    ldur x0, [x20, #0]      ; pega o estado atual do controlador e guarda no x0
    xor x0, x0, x21         ; flipa valor do clock

    ; esperar tempo pra flipar o clock
    ldur x1, [x31, #8]      ; carrega a constante de contagem do clock no x1

toggle_sck_clock_count:
    cbz x1, toggle_sck_continue ; Se chegou em 0, sai do loop
    sub x1, x1, x21             ; subtrai 1 na contagem
    b toggle_sck_clock_count    ; senão, volta pra subtrair

toggle_sck_continue:
    stur x0, [x20, #0]      ; guarda no controlador os valores corretos com o clock flipado

    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x1, [x29, #0]      ; pega o valor do x1 da stack
    sub x29, x29, x21       ; subtrai 1 no stack pointer
    ldur x0, [x29, #0]      ; pega o valor do x0 da stack
    br x30                  ; retorna da subrotina
; FIM DA TOGGLE_SCK
