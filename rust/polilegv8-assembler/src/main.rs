use polilegv8_assembler::{
    abrir_arquivo, criar_binarios, escrever_arquivo, formatar_arquivo, pegar_dados, puxar_labels,
};
use std::{env, fs};

// Uso: assembler <entrada.s> [instrucoes.mif] [dados.mif]
fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Uso: {} <entrada.s> [instrucoes.mif] [dados.mif]", args[0]);
        std::process::exit(1);
    }
    let saida_instrucoes = args.get(2).map(String::as_str).unwrap_or("instrucoes.mif");
    let saida_dados = args.get(3).map(String::as_str).unwrap_or("dados.mif");

    let conteudo = abrir_arquivo(&args[1]);
    let mut linhas: Vec<String> = conteudo.lines().map(String::from).collect();
    formatar_arquivo(&mut linhas);

    // Separa a seção de dados (".data") da de código (".text"), se existir.
    let mut codigo: Vec<String> = Vec::new();
    let mut dados: Vec<String> = Vec::new();
    let mut em_dados = false;
    for linha in linhas {
        match linha.as_str() {
            ".data" => em_dados = true,
            ".text" => em_dados = false,
            _ if em_dados => dados.push(linha),
            _ => codigo.push(linha),
        }
    }

    let labels = puxar_labels(&mut codigo);
    let binarios = criar_binarios(&codigo, labels);
    let dados_binarios = pegar_dados(dados);

    let mut arq_instr = fs::File::create(saida_instrucoes).unwrap();
    escrever_arquivo(&mut arq_instr, &binarios, 32, 1024);

    let mut arq_dados = fs::File::create(saida_dados).unwrap();
    escrever_arquivo(&mut arq_dados, &dados_binarios, 64, 4096);

    println!(
        "{} instruções -> {}, {} dados -> {}",
        binarios.len(),
        saida_instrucoes,
        dados_binarios.len(),
        saida_dados
    );
}
