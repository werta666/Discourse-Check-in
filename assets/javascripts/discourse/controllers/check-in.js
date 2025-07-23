import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import I18n from "I18n";

export default class CheckInController extends Controller {
  @service appEvents;
  
  @tracked activeTab = "check-in";
  @tracked showSuccessMessage = false;
  @tracked successMessage = "";

  constructor() {
    super(...arguments);
    this.setupEventListeners();
  }

  setupEventListeners() {
    this.appEvents.on("check-in:success", this, this.onCheckInSuccess);
    this.appEvents.on("check-in:makeup-success", this, this.onMakeupSuccess);
    this.appEvents.on("check-in:error", this, this.onCheckInError);
  }

  willDestroy() {
    super.willDestroy();
    this.appEvents.off("check-in:success", this, this.onCheckInSuccess);
    this.appEvents.off("check-in:makeup-success", this, this.onMakeupSuccess);
    this.appEvents.off("check-in:error", this, this.onCheckInError);
  }

  @action
  switchTab(tabName) {
    this.activeTab = tabName;
  }

  @action
  onCheckInSuccess(data) {
    let message = `✅ ${I18n.t("check_in.success.checked_in")} +${data.pointsEarned} ${I18n.t("check_in.points")}`;
    
    if (data.bonusPoints > 0) {
      message += ` (${I18n.t("check_in.success.bonus_included", { points: data.bonusPoints })})`;
    }
    
    this.showMessage(message);
  }

  @action
  onMakeupSuccess(data) {
    const message = `✅ ${I18n.t("check_in.success.makeup_completed")} ${data.date} (+${data.pointsEarned}, -${data.makeupCost})`;
    this.showMessage(message);
  }

  @action
  onCheckInError(data) {
    this.showMessage(`❌ ${data.message}`, "error");
  }

  @action
  showMessage(message, type = "success") {
    this.successMessage = message;
    this.showSuccessMessage = true;
    
    // Auto hide after 5 seconds
    setTimeout(() => {
      this.showSuccessMessage = false;
    }, 5000);
  }

  @action
  hideMessage() {
    this.showSuccessMessage = false;
  }

  get isCheckInTab() {
    return this.activeTab === "check-in";
  }

  get isRecordsTab() {
    return this.activeTab === "records";
  }

  get isMakeupTab() {
    return this.activeTab === "makeup";
  }
}
