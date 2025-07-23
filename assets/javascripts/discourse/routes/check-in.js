import DiscourseRoute from "discourse/routes/discourse";
import { inject as service } from "@ember/service";

export default class CheckInRoute extends DiscourseRoute {
  @service currentUser;
  @service router;

  beforeModel() {
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
  }

  model() {
    return {
      user: this.currentUser
    };
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set("user", model.user);
  }

  titleToken() {
    return "check_in.page_title";
  }
}
