use regex::Regex;
use std::{
    fs,
    io::{Read, Write},
};

const OPCODES: [&str; 13] = [
    "11111000010", // LDUR
    "11111000000", // STUR
    "10001011000", // ADD
    "11001011000", // SUB
    "10101010000", // ORR
    "10001010000", // AND
    "11010011011", // LSL
    "11010011010", // LSR
    "000101",      // B
    "10110100",    // CBZ
    "10101010100", // XORR
    "11010110000", // BR
    "100101",      // BL
];

pub fn pegar_dados(dados: Vec<String>) -> Vec<String> {
    let mut dados_binarios = Vec::new();
    let re_dado = Regex::new(r"(\d+)").unwrap();
    for dado in dados {
        dbg!(&dado);
        if let Some(caps) = re_dado.captures(&dado) {
            let convertido = caps[1].parse::<u128>().unwrap();
            dados_binarios.push(format!("{:064b}", convertido));
        }
    }
    dados_binarios
}
fn remover_comentario(linha: &str) -> &str {
    let mut dentro_colchete = false;
    for (i, c) in linha.char_indices() {
        match c {
            '[' => dentro_colchete = true,
            ']' => dentro_colchete = false,
            ';' if !dentro_colchete => return &linha[..i],
            _ => {}
        }
    }
    linha
}

pub fn abrir_arquivo(path: &String) -> String {
    let mut arquivo = String::new();
    fs::File::open(path)
        .unwrap()
        .read_to_string(&mut arquivo)
        .unwrap();

    arquivo
}

pub fn formatar_arquivo(arquivo: &mut Vec<String>) {
    let re_hexa = Regex::new(r"0x([\d\w]*)").unwrap();
    for linha in &mut *arquivo {
        *linha = remover_comentario(linha).to_string();
        *linha = linha.trim().to_string();
        *linha = linha.to_ascii_lowercase();
        if let Some(caps) = re_hexa.captures(linha) {
            let numero = u128::from_str_radix(&caps[1], 16).unwrap();
            let replace_str = format!("#{}", numero);
            *linha = linha.replace(&caps[0], &replace_str);
        }
    }
    arquivo.retain(|item| !item.is_empty());
}

pub fn criar_binarios(arquivo: &[String], labels: Vec<(usize, String)>) -> Vec<String> {
    let mut binarios: Vec<String> = Vec::new();
    let re_tipo_r = Regex::new(r"(\w*) *x(\d*), x(\d*), [x#](\d*)").unwrap();
    let re_tipo_d = Regex::new(r"(\w*) *x(\d*), \[x(\d*), #([-\d]*)\]").unwrap();
    let re_tipo_cb = Regex::new(r"cbz *x(\d*)[, ]*(.*)").unwrap();
    let re_tipo_b = Regex::new(r"b (\w*)").unwrap();
    let re_tipo_br = Regex::new(r"br x(\d*)").unwrap();
    let re_tipo_bl = Regex::new(r"bl (\w*)").unwrap();
    for (i, linha) in arquivo.iter().enumerate() {
        let mut binario = String::new();
        if let Some(caps) = re_tipo_r.captures(linha) {
            let mut shamt: String = String::from("000000");
            if &caps[1] == "add" {
                binario += OPCODES[2];
            } else if &caps[1] == "sub" {
                binario += OPCODES[3];
            } else if &caps[1] == "and" {
                binario += OPCODES[5];
            } else if &caps[1] == "orr" {
                binario += OPCODES[4];
            } else if &caps[1] == "xor" {
                binario += OPCODES[10];
            } else if &caps[1] == "lsr" {
                binario += OPCODES[7];
                shamt = format!("{:06b}", caps[4].parse::<u8>().unwrap());
            } else if &caps[1] == "lsl" {
                binario += OPCODES[6];
                shamt = format!("{:06b}", caps[4].parse::<u8>().unwrap());
            }
            let rm = caps[4].parse::<u8>().unwrap();
            binario += &(format!("{:05b}", if rm < 31 { rm } else { 0 })
                + &shamt
                + &format!("{:05b}", caps[3].parse::<u8>().unwrap())
                + &format!("{:05b}", caps[2].parse::<u8>().unwrap()))
        } else if let Some(caps) = re_tipo_d.captures(linha) {
            if &caps[1] == "ldur" {
                binario += OPCODES[0];
            } else if &caps[1] == "stur" {
                binario += OPCODES[1];
            }
            let offset = caps[4].parse::<i16>().unwrap() & 0x1FF;
            binario += &format!(
                "{:09b}00{:05b}{:05b}",
                offset,
                caps[3].parse::<u8>().unwrap(),
                caps[2].parse::<u8>().unwrap()
            );
        } else if let Some(caps) = re_tipo_cb.captures(linha) {
            let offset = labels.iter().find(|e| e.1 == caps[2]).unwrap().0 as i32 - i as i32;
            let offset = offset as u32 & 0x7FFFF;
            binario = OPCODES[9].to_string()
                + &format!("{:019b}{:05b}", offset, caps[1].parse::<i32>().unwrap());
        } else if let Some(caps) = re_tipo_b.captures(linha) {
            let offset =
                (labels.iter().find(|e| e.1 == caps[1]).unwrap().0 as i32 - i as i32) & 0x3FFFFFF;
            binario = OPCODES[8].to_string() + &format!("{:026b}", offset);
        } else if let Some(caps) = re_tipo_br.captures(linha) {
            let reg = caps[1].parse::<u8>().unwrap();
            binario = OPCODES[11].to_string() + &format!("00000000000{:05b}00000", reg);
        } else if let Some(caps) = re_tipo_bl.captures(linha) {
            let offset =
                (labels.iter().find(|e| e.1 == caps[1]).unwrap().0 as i32 - i as i32) & 0x3FFFFFF;
            binario = OPCODES[12].to_string() + &format!("{:026b}", offset);
        }
        binarios.push(binario);
    }
    binarios
}

pub fn puxar_labels(arquivo: &mut Vec<String>) -> Vec<(usize, String)> {
    let mut labels = Vec::new();
    let mut ja_foram = 0;
    for (i, linha) in arquivo.iter().enumerate() {
        if linha.ends_with(":") {
            labels.push((i - ja_foram, linha.split(":").next().unwrap().to_string()));
            ja_foram += 1;
        }
    }

    for (pos, _) in labels.iter().rev() {
        ja_foram -= 1;
        arquivo.remove(pos + ja_foram);
    }

    labels
}

pub fn escrever_arquivo(
    arquivo_dados: &mut fs::File,
    binarios: &[String],
    largura: u32,
    tamanho: u32,
) {
    let texto_inicial = format!(
        "WIDTH={};
DEPTH={};

ADDRESS_RADIX=HEX;
DATA_RADIX=BIN;

CONTENT BEGIN\n",
        largura, tamanho
    );

    arquivo_dados.write_all(texto_inicial.as_bytes()).unwrap();
    for (i, binario) in binarios.iter().enumerate() {
        let linha = format!("   {:04X} : {};\n", i, binario).to_string();
        arquivo_dados.write_all(linha.as_bytes()).unwrap();
    }
    if binarios.len() < tamanho as usize {
        let linha = format!(
            "   [{:04X}..{:04X}] : {};\n",
            binarios.len(),
            tamanho - 1,
            "0".repeat(largura as usize)
        );
        arquivo_dados.write_all(linha.as_bytes()).unwrap();
    }
    arquivo_dados.write_all(b"END;").unwrap();
}
