import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Component.extend({
  loading: false,
  checkedInToday: false,
  totalPoints: 0,
  consecutiveDays: 0,
  canCheckIn: true,
  nextBonusIn: null,
  settings: null,

  didInsertElement() {
    this._super(...arguments);
    this.set('settings', {});
    this.send('loadStatus');
  },

  actions: {
    loadStatus() {
    ajax("/check-in/check-in-status").then((response) => {
      if (response.success) {
        const data = response.data;
        this.setProperties({
          checkedInToday: data.checked_in_today,
          totalPoints: data.total_points,
          consecutiveDays: data.consecutive_days,
          canCheckIn: data.can_check_in,
          nextBonusIn: data.next_bonus_in,
          settings: data.settings
        });
      }
    }).catch((error) => {
      popupAjaxError(error);
    });
    },

    checkIn() {
    if (this.loading || !this.canCheckIn) return;

    this.set('loading', true);

    ajax("/check-in/check-in", {
      type: "POST"
    }).then((response) => {
      if (response.success) {
        this.setProperties({
          checkedInToday: true,
          canCheckIn: false,
          totalPoints: response.data.total_points,
          consecutiveDays: response.data.consecutive_days
        });

        // Show success message
        if (this.appEvents) {
          this.appEvents.trigger("check-in:success", {
            pointsEarned: response.data.points_earned,
            bonusPoints: response.data.bonus_points,
            consecutiveDays: response.data.consecutive_days
          });
        }

        // Refresh status after a short delay
        setTimeout(() => this.send('loadStatus'), 1000);
      }
    }).catch((error) => {
      popupAjaxError(error);
    }).finally(() => {
      this.set('loading', false);
    });
    }
  },

  buttonText: function() {
    if (this.loading) {
      return I18n.t("check_in.button.checking_in");
    }

    if (this.checkedInToday) {
      return I18n.t("check_in.button.checked_in");
    }

    return I18n.t("check_in.button.check_in");
  }.property('loading', 'checkedInToday'),

  buttonClass: function() {
    let classes = ["btn", "check-in-button"];

    if (this.checkedInToday) {
      classes.push("btn-success");
    } else if (this.canCheckIn) {
      classes.push("btn-primary");
    } else {
      classes.push("btn-default");
    }

    if (this.loading) {
      classes.push("loading");
    }

    return classes.join(" ");
  }.property('checkedInToday', 'canCheckIn', 'loading'),

  statusText: function() {
    if (this.checkedInToday) {
      return I18n.t("check_in.status.checked_in_today");
    }

    if (!this.get('settings.check_in_enabled')) {
      return I18n.t("check_in.status.disabled");
    }

    return I18n.t("check_in.status.ready_to_check_in");
  }.property('checkedInToday', 'settings.check_in_enabled'),

  pointsInfo: function() {
    const dailyPoints = this.get('settings.daily_points') || 0;
    let info = I18n.t("check_in.info.daily_points", { points: dailyPoints });

    if (this.get('settings.consecutive_bonus_enabled') && this.nextBonusIn !== null) {
      if (this.nextBonusIn === 0) {
        info += " " + I18n.t("check_in.info.bonus_today", {
          points: this.get('settings.consecutive_bonus_points')
        });
      } else {
        info += " " + I18n.t("check_in.info.bonus_in_days", {
          days: this.nextBonusIn,
          points: this.get('settings.consecutive_bonus_points')
        });
      }
    }

    return info;
  }.property('settings.daily_points', 'settings.consecutive_bonus_enabled', 'nextBonusIn', 'settings.consecutive_bonus_points')
});
