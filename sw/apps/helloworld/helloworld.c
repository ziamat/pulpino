// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

#include "gpio.h"
#include "pulpino.h"
#include "string_lib.h"

#define NUM_SW_LED 4
#define NUM_BTN 4
#define NUM_PMOD 5

int sw_pins[NUM_SW_LED] = {0, 1, 2, 3};    // SW0 - SW3 (GPIO 0-3)
int led_pins[NUM_SW_LED] = {8, 9, 10, 11}; // LD0 - LD3 (GPIO 8-11)
int btn_pins[NUM_BTN] = {16, 17, 18, 19};  // BTN0 - BTN3 (GPIO 16-19)
const char *btn_messages[NUM_BTN] = {"RI5CY (BTN0)", "PULPINO (BTN1)",
                                     "ACHMAD (BTN2)", "MUHAJIR (BTN3)"};
int pmod_pins[NUM_PMOD] = {
    20, // PMOD JC Pin 2
    5,  // PMOD JB Pin 7
    4,  // PMOD JB Pin 8
    7,  // PMOD JB Pin 9
    6   // PMOD JB Pin 10
};

const char *pmod_names[NUM_PMOD] = {"PMOD JC Pin 2", "PMOD JB Pin 7",
                                    "PMOD JB Pin 8", "PMOD JB Pin 9",
                                    "PMOD JB Pin 10"};

int main() {
  printf("\n==================Hello World!!!==================\n");
  printf("==================================================\n");
  printf("          SISTEM DIAGNOSTIK GPIO & PMOD\n");
  printf("==================================================\n");

  CGREG |= (1 << CGGPIO);

  for (int i = 0; i < NUM_SW_LED; i++) {
    set_pin_function(sw_pins[i], FUNC_GPIO);
    set_gpio_pin_direction(sw_pins[i], DIR_IN);

    set_pin_function(led_pins[i], FUNC_GPIO);
    set_gpio_pin_direction(led_pins[i], DIR_OUT);
    set_gpio_pin_value(led_pins[i], 0);
  }

  for (int i = 0; i < NUM_BTN; i++) {
    set_pin_function(btn_pins[i], FUNC_GPIO);
    set_gpio_pin_direction(btn_pins[i], DIR_IN);
  }

  for (int i = 0; i < NUM_PMOD; i++) {
    set_pin_function(pmod_pins[i], FUNC_GPIO);
    set_gpio_pin_direction(pmod_pins[i], DIR_IN);
  }

  int last_btn_states[NUM_BTN] = {0, 0, 0, 0};
  int last_pmod_states[NUM_PMOD] = {-1, -1, -1, -1, -1};

  printf("Sistem siap. Memulai pemantauan...\n\n");

  while (1) {
    for (int i = 0; i < NUM_SW_LED; i++) {
      int sw_val = get_gpio_pin_value(sw_pins[i]);
      set_gpio_pin_value(led_pins[i], sw_val);
    }

    for (int i = 0; i < NUM_BTN; i++) {
      int current_btn_val = get_gpio_pin_value(btn_pins[i]);

      if (current_btn_val == 1 && last_btn_states[i] == 0) {
        printf("[BUTTON FEEDBACK] %s\n", btn_messages[i]);
      }

      last_btn_states[i] = current_btn_val;
    }

    for (int i = 0; i < NUM_PMOD; i++) {
      int current_pmod_val = get_gpio_pin_value(pmod_pins[i]);

      if (current_pmod_val != last_pmod_states[i]) {
        printf("[PMOD FEEDBACK] %s (GPIO %d) berubah menjadi: %s\n",
               pmod_names[i], pmod_pins[i],
               (current_pmod_val == 1) ? "HIGH (3.3V)" : "LOW (0V)");

        last_pmod_states[i] = current_pmod_val;
      }
    }

    for (volatile int delay = 0; delay < 50000; delay++)
      ;
  }

  return 0;
}
