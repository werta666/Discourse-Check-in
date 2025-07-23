import { ajax } from "discourse/lib/ajax";
import Component from "@ember/component";

export default Component.extend({
  loading: false,
  message: "Click to check in",

  actions: {
    checkIn() {
      this.set('loading', true);
      this.set('message', 'Checking in...');

      ajax("/check-in/check-in", {
        type: "POST"
      }).then((response) => {
        if (response && response.success) {
          this.set('message', 'Check-in successful! Points: ' + (response.data ? response.data.points_earned : 'Unknown'));
        } else {
          this.set('message', 'Check-in failed');
        }
      }).catch((error) => {
        this.set('message', 'Error occurred during check-in');
        console.error('Check-in error:', error);
      }).finally(() => {
        this.set('loading', false);
      });
    }
  }
});
