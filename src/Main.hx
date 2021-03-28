import ui.MainMenu;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;

	public var controller : dn.heaps.Controller;
	public var ca : dn.heaps.Controller.ControllerAccess;

	public var debug = false;

	public function new(s : h2d.Scene) {
		super();
		ME = this;

		createRoot(s);

		// Engine settings
		hxd.Timer.wantedFPS = Const.FPS;
		engine.backgroundColor = 0xff << 24 | 0x111133;
		#if (hl && !debug)
		engine.fullScreen = true;
		#end

		sys.FileSystem.createDirectory('save');

		// Assets & data init
		Assets.init();
		new ui.Console(Assets.fontTiny, s);
		Lang.init("en");

		// Game controller
		controller = new dn.heaps.Controller(s);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(AXIS_LEFT_Y_POS, Key.UP, Key.Z);
		controller.bind(AXIS_LEFT_Y_NEG, Key.DOWN, Key.S);
		controller.bind(X, Key.F);
		controller.bind(Y, Key.C);
		controller.bind(A, Key.E);
		controller.bind(B, Key.SPACE);
		controller.bind(SELECT, Key.R);
		controller.bind(START, Key.ESCAPE);

		// Focus helper (process that suspend the game when the focus is lost)
		new GameFocusHelper();

		new Options();
		Options.ME.load();

		// Start
		delayer.addF(startMainMenu, 1);
		#if debug
		debug = true;
		#end
	}

	public function startMainMenu() {
		killAllChildrenProcesses();

		if (MainMenu.ME != null) {
			MainMenu.ME.destroy();
			delayer.addF(function() {
				new MainMenu();
			}, 1);
		} else
			new MainMenu();
	}

	public function startGame() {
		if (Game.ME != null) {
			Game.ME.destroy();
			delayer.addF(function() {
				new Game();
			}, 1);
		} else
			new Game();
	}

	override public function onResize() {
		super.onResize();

		// Auto scaling
		if (Const.AUTO_SCALE_TARGET_WID > 0)
			Const.SCALE = M.ceil(w() / Const.AUTO_SCALE_TARGET_WID);
		else if (Const.AUTO_SCALE_TARGET_HEI > 0)
			Const.SCALE = M.ceil(h() / Const.AUTO_SCALE_TARGET_HEI);

		if (Const.AUTO_SCALE_UI_TARGET_HEI > 0)
			Const.UI_SCALE = Math.max(1., h() / Const.AUTO_SCALE_UI_TARGET_HEI);
	}

	override function update() {
		super.update();

		#if debug
		if (debug) {
			updateImGui();
		}
		#end
	}

	#if debug
	function updateImGui() {
		var halfBtnSize : ImVec2 = {x: ImGui.getColumnWidth() / 2 - 5, y: ImGui.getTextLineHeightWithSpacing()};
		if (ImGui.button('New game', halfBtnSize)) {
			hxd.Save.delete('save/game');
			delayer.addF(startGame, 1);
		}
		if (Options.ME != null && ImGui.treeNodeEx('Options')) {
			if (ImGui.button('Save', halfBtnSize))
				Options.ME.save();
			ImGui.sameLine(0, 5);
			if (ImGui.button('Load', halfBtnSize))
				Options.ME.load();

			Options.ME.imGuiDebugFields();

			ImGui.treePop();
		}
		ImGui.separator();
	}
	#end

	#if debug
	var imguiCaptureMouse = false;
	#end
	override function postUpdate() {
		super.postUpdate();

		#if debug
		if (hxd.Key.isPressed(hxd.Key.F1)) {
			debug = !debug;
			if (!debug) {
				imguiCaptureMouse = false;
				controller.unlock();
			}
		}

		if (debug) {
			if (ImGui.wantCaptureMouse()) {
				if (!imguiCaptureMouse && !controller.isLocked()) {
					imguiCaptureMouse = true;
					controller.lock();
				}
			} else if (imguiCaptureMouse) {
				imguiCaptureMouse = false;
				controller.unlock();
			}
		}
		#end
	}
}
