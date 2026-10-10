# PoliLegV8 Sequenciador

Sequenciador de sintetizadores analógicos feito em FPGA: um processador **LEGv8** escrito em VHDL lê as notas de um **cartão micro-SD** e controla o VCO de um sintetizador.

```
 micro-SD ──SPI──▶ PoliLegV8 (FPGA) ──GPIO──▶ escala 1V/oitava ──▶ VCO do sintetizador
   (notas)          lê e executa o              (tensão de            (o som sai
                    programa em assembly         controle)             aqui)
```

## O que tem aqui

| Pasta | Conteúdo |
|---|---|
| `polilegv8/` | Processador em VHDL e projeto do Quartus (FPGA) |
| `assembly/sdcard_polilegv8/` | Programa em assembly LEGv8 que roda no processador: lê o cartão SD e toca as notas |
| `rust/` | Ferramentas de apoio escritas em Rust: o assembler do PoliLegV8 e o programador de cartão SD |
| `bin/` | Binários prontos das ferramentas, para quem não quer compilar |

## Hardware

- Placa **Altera DE0-CV** (FPGA Cyclone V)
- Cartão **micro-SD**, ligado ao processador por SPI
- Sintetizador analógico com entrada de controle de **1V por oitava** (a escala é feita a partir dos pinos GPIO da placa)

## O processador

O PoliLegV8 é um processador **single-cycle** baseado no subconjunto do LEGv8, com:

- mecanismo de **stall**, para esperar as operações lentas do cartão SD
- comunicação **SPI** com o cartão
- **E/S mapeada em memória**
- extensões ao conjunto de instruções: `BR`, `BL`, `XOR`, `LSL` e `LSR`

## O assembler

O assembler (em `rust/`) converte um programa `.s` nos arquivos `.mif` que o Quartus usa para inicializar as memórias do processador. Resolve labels em duas passadas.

Instruções suportadas:

| Tipo | Instruções |
|---|---|
| Aritmética e lógica | `ADD`, `SUB`, `AND`, `ORR`, `XOR` |
| Deslocamento | `LSL`, `LSR` |
| Memória | `LDUR`, `STUR` |
| Desvios | `B`, `BL`, `BR`, `CBZ` |

Exemplo de programa:

```asm
inicio:
    add  x1, x2, x3          ; comentários começam com ponto e vírgula
    ldur x5, [x6, #8]
    lsl  x7, x1, #3
    cbz  x1, fim
    bl   func
    b    inicio
func:
    xor  x8, x1, x2
    br   x30
fim:
    orr  x9, x1, x2
```

Registradores são escritos como `x0` a `x30`, imediatos como `#10` e valores hexadecimais como `0x1F`.

### Compilar e usar

```bash
cd rust/polilegv8-assembler
cargo build --release

./target/release/assembler programa.s instrucoes.mif dados.mif
```

A saída tem palavras de 32 bits e profundidade 1024 para as instruções. Os dois últimos argumentos opcionais mudam a profundidade das memórias de instruções e de dados.

## Como rodar tudo

1. Escreva (ou edite) o programa em `assembly/sdcard_polilegv8/`.
2. Gere os `.mif` com o assembler.
3. Abra o projeto de `polilegv8/` no **Quartus**, compile e grave na DE0-CV.
4. Grave no cartão micro-SD os arquivos de notas gerados pelo programador do SD.
5. Ligue a saída de GPIO ao circuito de 1V/oitava e ao VCO do sintetizador.

## Autor

Feito por [Theo Amaral](https://github.com/theo-amaral).
