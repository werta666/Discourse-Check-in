import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Component.extend({
  loading: false,
  message: "Click to check in",

  actions: {
    checkIn() {
      this.set('loading', true);
      this.set('message', 'Checking in...');
      
      ajax("/check-in/check-in", {
        type: "POST"
      }).then((response) => {
        if (response.success) {
          this.set('message', 'Check-in successful! Points: ' + response.data.points_earned);
        } else {
          this.set('message', 'Check-in failed');
        }
      }).catch((error) => {
        this.set('message', 'Error: ' + error.message);
        popupAjaxError(error);
      }).finally(() => {
        this.set('loading', false);
      });
    }
  }
});
