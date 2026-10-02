#!/bin/sh

# Mapping dos pinos da HAT ELECROW SX1302
SX1302_RESET_PIN=17     # SX1302 reset
SX1302_POWER_EN_PIN=18 # SX1302 power enable
SX1261_RESET_PIN=5     # SX1261 reset
AD5338R_RESET_PIN=13   # AD5338R reset

WAIT_GPIO() {
    sleep 0.1
}

# Função para definir o pino e MANTER o estado no hardware
set_pin_high() {
    PIN=$1
    if command -v pinctrl >/dev/null 2>&1; then
        pinctrl set $PIN op dh
    elif command -v raspi-gpio >/dev/null 2>&1; then
        raspi-gpio set $PIN op dh
    else
        # Se usar gpioset, precisamos deixar um processo rodando em background para manter o estado
        gpioset -c gpiochip4 $PIN=1 >/dev/null 2>&1 &
    fi
}

set_pin_low() {
    PIN=$1
    if command -v pinctrl >/dev/null 2>&1; then
        pinctrl set $PIN op dl
    elif command -v raspi-gpio >/dev/null 2>&1; then
        raspi-gpio set $PIN op dl
    else
        gpioset -c gpiochip4 $PIN=0 >/dev/null 2>&1 &
    fi
}

reset() {
    echo "Iniciando reset persitente do concentrador SX1302..."

    # Garante encerramento de processos gpioset anteriores se existirem
    killall gpioset >/dev/null 2>&1

    # Power Enable -> High (Alimenta a HAT e MANTÉM alimentado)
    set_pin_high $SX1302_POWER_EN_PIN
    WAIT_GPIO

    # Pulso de Reset no SX1302 (High -> Low)
    set_pin_high $SX1302_RESET_PIN
    WAIT_GPIO
    set_pin_low $SX1302_RESET_PIN
    WAIT_GPIO

    # Resets secundários
    set_pin_low $SX1261_RESET_PIN
    WAIT_GPIO
    set_pin_high $SX1261_RESET_PIN

    set_pin_low $AD5338R_RESET_PIN
    WAIT_GPIO
    set_pin_high $AD5338R_RESET_PIN
    WAIT_GPIO
}

term() {
    echo "Desligando concentrador..."
    killall gpioset >/dev/null 2>&1
    set_pin_low $SX1302_POWER_EN_PIN
    set_pin_low $SX1302_RESET_PIN
}

case "$1" in
    start) reset ;;
    stop) term ;;
    *) reset ;;
esac

exit 0
