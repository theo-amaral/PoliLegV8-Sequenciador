use regex::Regex;
use std::env::args;
use std::fs;
use std::io::{Read, Write};

const CLOCK_FREQ: usize = 10_000_000;

const NOTAS: [&str; 12] = [
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
];

fn data_converter(note: usize, oct: usize) -> u8 {
    (2 * note + 24 * oct) as u8
}

fn main() {
    let args: Vec<String> = args().collect();
    let mut data: [u8; 512] = [0; 512];
    let mut file_write = fs::File::create("binario.bin").unwrap();
    let mut file_read = String::new();
    fs::File::open(&args[1])
        .unwrap()
        .read_to_string(&mut file_read)
        .unwrap();

    let contagem = CLOCK_FREQ
        / (file_read.split_terminator("\n").collect::<Vec<&str>>()[0]
            .parse::<usize>()
            .unwrap()
            / 20);

    let re_notas = Regex::new(r"([a-zA-Z#]+)(\d)").unwrap();

    let notas: Vec<(usize, usize)> = re_notas
        .captures_iter(&file_read)
        .map(|caps| {
            let (_, [nota, oitava]) = caps.extract();
            (
                NOTAS.iter().position(|&x| nota == x).unwrap(),
                oitava.parse::<usize>().unwrap(),
            )
        })
        .collect();

    println!("Numero de notas: {}", notas.len())
    data[0] = ((notas.len() >> 16) & 0xFF) as u8;
    data[1] = (notas.len() & 0xFF) as u8;
    data[2] = ((contagem >> 24) & 0xFF) as u8;
    data[3] = ((contagem >> 16) & 0xFF) as u8;
    data[4] = ((contagem >> 8) & 0xFF) as u8;
    data[5] = (contagem & 0xFF) as u8;

    for (i, nota) in notas.iter().enumerate() {
        data[i + 6] = data_converter(nota.0, nota.1);
    }

    file_write.write_all(&data).unwrap();
}
