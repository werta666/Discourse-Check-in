import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";

export default class CheckInButton extends Component {
  @service currentUser;
  @service appEvents;
  
  @tracked loading = false;
  @tracked checkedInToday = false;
  @tracked totalPoints = 0;
  @tracked consecutiveDays = 0;
  @tracked canCheckIn = true;
  @tracked nextBonusIn = null;
  @tracked settings = {};

  constructor() {
    super(...arguments);
    this.loadStatus();
  }

  @action
  async loadStatus() {
    try {
      const response = await ajax("/check-in/check-in-status");
      if (response.success) {
        const data = response.data;
        this.checkedInToday = data.checked_in_today;
        this.totalPoints = data.total_points;
        this.consecutiveDays = data.consecutive_days;
        this.canCheckIn = data.can_check_in;
        this.nextBonusIn = data.next_bonus_in;
        this.settings = data.settings;
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async checkIn() {
    if (this.loading || !this.canCheckIn) return;

    this.loading = true;
    
    try {
      const response = await ajax("/check-in/check-in", {
        type: "POST"
      });

      if (response.success) {
        this.checkedInToday = true;
        this.canCheckIn = false;
        this.totalPoints = response.data.total_points;
        this.consecutiveDays = response.data.consecutive_days;
        
        // Show success message
        this.appEvents.trigger("check-in:success", {
          pointsEarned: response.data.points_earned,
          bonusPoints: response.data.bonus_points,
          consecutiveDays: response.data.consecutive_days
        });

        // Refresh status after a short delay
        setTimeout(() => this.loadStatus(), 1000);
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  get buttonText() {
    if (this.loading) {
      return I18n.t("check_in.button.checking_in");
    }
    
    if (this.checkedInToday) {
      return I18n.t("check_in.button.checked_in");
    }
    
    return I18n.t("check_in.button.check_in");
  }

  get buttonClass() {
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
  }

  get statusText() {
    if (this.checkedInToday) {
      return I18n.t("check_in.status.checked_in_today");
    }
    
    if (!this.settings.check_in_enabled) {
      return I18n.t("check_in.status.disabled");
    }
    
    return I18n.t("check_in.status.ready_to_check_in");
  }

  get pointsInfo() {
    const dailyPoints = this.settings.daily_points || 0;
    let info = I18n.t("check_in.info.daily_points", { points: dailyPoints });
    
    if (this.settings.consecutive_bonus_enabled && this.nextBonusIn !== null) {
      if (this.nextBonusIn === 0) {
        info += " " + I18n.t("check_in.info.bonus_today", { 
          points: this.settings.consecutive_bonus_points 
        });
      } else {
        info += " " + I18n.t("check_in.info.bonus_in_days", { 
          days: this.nextBonusIn,
          points: this.settings.consecutive_bonus_points 
        });
      }
    }
    
    return info;
  }
}
