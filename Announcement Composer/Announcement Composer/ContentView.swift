//
//  ContentView.swift
//  Announcement Composer
//
//  Created by Gabriel Jacoby-Cooper on 11/16/21.
//

import SwiftUI

struct ContentView: View {
	
	@State private var announcement = Announcement()
	
	@State private var baseURLString = "https://shuttletracker.app"
	
	@State private var doShowSuccessAlert = false
	
	@State private var selectedKeyPair: KeyPair?
	
	@State private var error: WrappedError?
	
	@AppStorage("KeyPairs") private var keyPairs = [KeyPair]()
	
	var body: some View {
		VStack {
			Form {
				Section {
					TextField("Subject", text: self.$announcement.subject, prompt: Text("Subject"))
						.labelsHidden()
					TextEditor(text: self.$announcement.body)
				} header: {
					Text("Content")
						.font(.headline)
				}
				Divider()
					.padding(.vertical, 10)
				Section {
					HStack {
						VStack {
							HStack {
								Toggle("Begin showing on a particular date", isOn: self.$announcement.hasStart)
								Spacer()
							}
							if self.announcement.hasStart {
								DatePicker("Start", selection: self.$announcement.start)
									.labelsHidden()
							}
						}
							.frame(maxWidth: .infinity)
						Spacer(minLength: 20)
						VStack {
							HStack {
								Toggle("Finish showing on a particular date", isOn: self.$announcement.hasEnd)
								Spacer()
							}
							if self.announcement.hasEnd {
								DatePicker("End", selection: self.$announcement.end)
									.labelsHidden()
							}
						}
							.frame(maxWidth: .infinity)
					}
				} header: {
					Text("Schedule")
						.font(.headline)
				}
				Divider()
					.padding(.vertical, 10)
				Section {
					HStack {
						Picker("Key", selection: self.$selectedKeyPair) {
							ForEach(self.keyPairs) { (keyPair) in
								Text(keyPair.name)
									.tag(Optional(keyPair))
							}
						}
							.labelsHidden()
							.disabled(self.keyPairs.isEmpty)
						Button("Open Key Manager…") {
							WindowManager.show(.keyManager)
						}
					}
				} header: {
					Text("Key")
						.font(.headline)
				}
				Divider()
					.padding(.vertical, 10)
				Section {
					TextField("Base URL", text: self.$baseURLString, prompt: Text("Base URL"))
						.labelsHidden()
				} header: {
					Text("Server")
						.font(.headline)
				}
			}
			Divider()
				.padding(.vertical, 10)
			HStack {
				Button("Clear", role: .destructive) {
					self.announcement.subject = ""
					self.announcement.body = ""
					self.announcement.hasStart = false
					self.announcement.hasEnd = false
					self.selectedKeyPair = nil
				}
				Spacer()
				Button("Submit") {
					guard let selectedKeyPair = self.selectedKeyPair else {
						self.error = WrappedError(SubmissionError.noKeySelected)
						return
					}
					do {
						try self.announcement.sign(with: selectedKeyPair)
					} catch let newError {
						self.error = WrappedError(newError)
						return
					}
					Task {
						guard let baseURL = URL(string: self.baseURLString) else {
							let newError = SubmissionError.invalidBaseURL
							self.error = WrappedError(newError)
							throw newError
						}
						let url = baseURL.appendingPathComponent("announcements", isDirectory: false)
						var request = URLRequest(url: url)
						request.httpMethod = "POST"
						do {
							let data = try JSONEncoder().encode(self.announcement)
							_ = try await URLSession.shared.upload(for: request, from: data)
						} catch let newError {
							self.error = WrappedError(newError)
							throw newError
						}
						self.doShowSuccessAlert = true
					}
				}
					.keyboardShortcut(.defaultAction)
					.disabled(self.announcement.subject.isEmpty || self.announcement.body.isEmpty || self.selectedKeyPair == nil)
			}
		}
			.padding()
			.animation(.default, value: self.announcement.hasStart)
			.animation(.default, value: self.announcement.hasEnd)
			.toolbar {
				ToolbarItem {
					Button {
						WindowManager.show(.keyManager)
					} label: {
						Label("Key Manager", systemImage: "key")
					}
				}
			}
			.alert(isPresented: self.$error.isNotNil, error: self.error) {
				Button("Continue") { }
			}
			.alert("The submission was successful!", isPresented: self.$doShowSuccessAlert) {
				Button("Continue") { }
			}
	}
	
}

struct ContentViewPreviews: PreviewProvider {
	
	static var previews: some View {
		ContentView()
	}
	
}
