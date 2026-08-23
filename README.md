# intel-x86-matrix-processor
Projeto final desenvolvido para a discipina de Arquitetura de Computadores da UFRGS.

[![Architecture](https://img.shields.io/badge/Architecture-Intel%20x86%2016--bit-blue.svg)](https://en.wikipedia.org/wiki/x86)
[![Environment](https://img.shields.io/badge/Environment-DOSBox%20%2F%20MS--DOS-orange.svg)](https://www.dosbox.com/)
[![Assembler](https://img.shields.io/badge/Assembler-MASM-green.svg)](https://mremoteng.org/)

Programa em **Intel Assembly x86** desenvolvido para a disciplina de **Arquitetura e Organização de Computadores I** da UFRGS.

O projeto consiste no carregamento, procesamento, exibição e manipulação de matrizes de números inteiros armazenadas em arquivos de texto, permitindo operações aritméticas linha a linha, histórico para undo e salvamento.

## Sumário
- [Funcionalidades](#-funcionalidades)
- [Formato do Arquivo de Entrada](#-formato-do-arquivo-de-entrada)
- [Comandos Suportados](#-comandos-suportados)
- [Exibição na Tela](#-exibição-na-tela)
- [Estrutura e Representação de Dados](#-estrutura-e-representação-de-dados)
- [Ambiente de Execução e Compilação](#-ambiente-de-execução-e-compilação)
- [Como Executar](#-como-executar)
- [Tratamento de Erros](#-tratamento-de-erros)
- [Autor](#-autor)

## Funcionalidades

- **Leitura e validação**: Carrega a matriz do arquivo padrão `MAT.TXT`, verificando a integridade do formato e suas dimensões.
- **Identificação de dimensão**: Detecta a dimensão $N$ da matriz ($N$ linhas por $N+1$ colunas, onde $2 \le N \le 7$).
- **Operações aritméticas**:
  - Multiplicação de linha por escalar (`MUL`).
  - Soma entre duas linhas com substituição da linha de destino (`ADD`).
  - Sistema de Desfazer (`UNDO`): Permite reverter a última alteração efetuada na matriz.
  - Exportação (`WRITE`): Grava o estado atual da matriz ao final de um arquivo de saída especificado pelo usuário.
  - Interface em Modo Texto: Exibe a matriz formatada com alinhamento à direita e espaçamento.

## Formato da Entrada (MAT.TXT)

O arquivo de entrada deve atender às seguintes regras:
1. **Nome padrão**: `MAT.TXT`.
2. **Dimensões**: $N$ linhas e $N+1$ colunas ($2 \le N \le 7$).
3. **Delimitador**: Caractere ponto e vírgula (`;`) entre os números.
4. **Sem Espaços**: Não são permitidos espaços, tabulações ou caracteres invisíveis adicionais.
5. **Representação Numérica**: Inteiros de 16 bits com sinal (em complemento de 2). Números negativos possuem o prefixo `-`.

### Exemplo de `MAT.TXT` ($N = 3$)
```text
4;-2;1;3
2;1;-1;1
1;-1;3;8
