use std::thread::sleep;
use std::time::Duration;
use clap::{arg, ArgAction, Command};
use reqwest::blocking::Client;
use reqwest::StatusCode;


fn main() {
    let cli = Command::new("HTTP Status Monitor")
        .version("1.0")
        .author("Your Name")
        .about("Monitors HTTP status changes of a URL")
        .arg(
            arg!(--url <VALUE>).required(true).action(ArgAction::Set)
        )
        .get_matches();

    let url = cli.get_one::<String>("url").expect("required");
    let client = Client::builder()
        .danger_accept_invalid_certs(true)
        .build().unwrap_or_else(| _result | panic!("Unable to create client!"));
    let mut previous_status_option: Option<StatusCode> = None;

    loop {
        match client.get(url).send() {
            Ok(result) => {
                let status_code = result.status();
                match previous_status_option {
                    Some(previous_status)
                    if status_code.as_u16() != previous_status.as_u16() => {
                        println!("Status changed to {:?}", status_code)
                    }
                    None => {
                        println!("Status changed to {:?}", status_code)
                    }
                    _ => {}
                }
                previous_status_option = Some(status_code);
            }
            Err(error) => {
                if !previous_status_option.is_none() {
                    println!("Error: {}", error);
                }
                previous_status_option = None;
            }
        }
        sleep(Duration::from_secs(5));
    }
}
