//
//  ZebrunnerApiClient.swift
//  
//
//  Created by Dzmitry Prymudrau on 20.07.22.
//

import Foundation
import XCTest

public class ZebrunnerApiClient {
    
    private static var instance: ZebrunnerApiClient?
    private var requestMgr: RequestManager!
    private var configuration: Configuration!
    private var testRunResponse: TestRunStartResponse?
    private var testCasesExecuted: [String: Int] = [:]
    
    private init(configuration: Configuration) {
        self.configuration = configuration
        self.requestMgr = RequestManager(baseUrl: configuration.baseUrl, refreshToken: configuration.accessToken)
        if let authToken = self.authenticate() {
            self.requestMgr.setAuthToken(authToken: authToken)
        }
    }
    
    public static func setUp(configuration: Configuration) -> ZebrunnerApiClient? {
        if (self.instance == nil) {
            self.instance = ZebrunnerApiClient(configuration: configuration)
        }
        return instance
    }
    
    public static func getInstance() throws -> ZebrunnerApiClient {
        guard let instance = ZebrunnerApiClient.instance else {
            throw ZebrunnerAgentError(description: "There was no instance of ZebrunnerApiClient created")
        }
        return instance
    }
    
    /// Send authentication request to get authToken for future requests
    /// - Returns String auth token
    private func authenticate() -> String? {
        let request = self.requestMgr.buildAuthRequest()
        let (data, _, error) = URLSession.shared.syncRequest(with: request)
        
        //Check if data exists and can be mapped
        guard let data = data else {
            print("Failed to authenticate: \(String(describing: error?.localizedDescription))")
            return nil
        }
        guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
            print("Failed to map response into AuthResponse from: \(data)")
            return nil
        }
        
        return authResponse.authToken
    }
    
    /// Creates a new test run on Zebrunner
    /// - Parameter testRunStartRequest: details to start test run
    public func startTestRun(testRunStartRequest: TestRunStartDTO) {
        let request = requestMgr.buildStartTestRunRequest(projectKey: configuration.projectKey,
                                                          testRunStartRequest: testRunStartRequest)
        let (data, _, error) = URLSession.shared.syncRequest(with: request)
        
        guard let data = data else {
            print("Failed to create Test Run: \(String(describing: error?.localizedDescription))")
            return
        }
        if let testRunStartResponse = try? JSONDecoder().decode(TestRunStartResponse.self, from: data) {
            self.testRunResponse = testRunStartResponse
        }
    }
    
    
    /// Finishes existing test run on Zebrunner
    ///  - Parameters:
    ///   - testRunFinishRequest: details to finish test run
    public func finishTestRun(testRunFinishRequest: TestRunFinishDTO) {
        guard let id = testRunResponse?.id else {
            print("There is no test run id found \(String(describing: testRunResponse))")
            return
        }
        let request = requestMgr.buildFinishTestRunRequest(testRunId: id, testRunFinishRequest: testRunFinishRequest)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Starts test case execution in given test run on Zebrunner
    ///  - Parameters:
    ///     - testCaseStartRequest: details to start test case
    public func startTest(testCaseStartRequest: TestCaseStartDTO) {
        guard let id = testRunResponse?.id else {
            print("There is no test run id found \(String(describing: testRunResponse))")
            return
        }
        let request = requestMgr.buildStartTestRequest(testRunId: id, testCaseStartRequest: testCaseStartRequest)
        let (data, _, error) = URLSession.shared.syncRequest(with: request)
        guard let data = data else {
            print("Failed to create test case execution: \(String(describing: error?.localizedDescription))")
            return
        }
        guard let testCaseStartResponse = try? JSONDecoder().decode(TestCaseStartResponse.self, from: data) else {
            print("Failed to map start test case response into TestCaseStartResponse from: \(data)")
            return
        }
        
        self.testCasesExecuted[testCaseStartResponse.name] = testCaseStartResponse.id
    }
    
    /// Finishes test case on Zebrunner with the reason of the result
    ///  - Parameters:
    ///     - testCaseName: test case name
    ///     - testCaseFinishRequest: details to finish test case
    public func finishTest(testCaseName: String, testCaseFinishRequest: TestCaseFinishDTO) {
        guard let id = testRunResponse?.id else {
            print("There is no test run id found \(String(describing: testRunResponse))")
            return
        }
        let request = requestMgr.buildFinishTestRequest(testRunId: id,
                                                        testId: self.testCasesExecuted[testCaseName]!,
                                                        testCaseFinishRequest: testCaseFinishRequest)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Updates test case data on Zebrunner
    ///  - Parameters:
    ///    - testCaseUpdateRequest: details to update test case
    public func updateTest(testCaseUpdateRequest: TestCaseUpdateDTO) {
        guard let id = testRunResponse?.id else {
            print("There is no test run id found \(String(describing: testRunResponse))")
            return
        }
        let request = requestMgr.buildUpdateTestRequest(testRunId: id, testId: self.testCasesExecuted[testCaseUpdateRequest.name]!, testCaseUpdateRequest: testCaseUpdateRequest)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Sends bulk logs for given test case
    /// - Parameters:
    ///   - testCaseName: name of test case to send logs
    ///   - logMessages: log messages to send
    ///   - level: log level of log messages
    ///   - timestamp: timestamp for log messages
    public func sendLogs(testCaseName: String, logMessages: [String], level: LogLevel, timestamp: String){
        guard let testCaseId = testCasesExecuted[testCaseName] else {
            print("There is no test case found in test run \(String(describing: testRunResponse))")
            return
        }
        let request = requestMgr.buildLogRequest(testRunId: getTestRunId(), testId: testCaseId, logMessages: logMessages, level: level, timestamp: timestamp)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Attaches a screenshot for given test case
    ///  - Parameters:
    ///     - testCaseName: name of test case to attach screenshot
    ///     - screenshot: png representation of screenshot
    public func sendScreenshot(_ testCaseName: String, screenshot: Data?) {
        guard let testCaseId = testCasesExecuted[testCaseName] else {
            print("There is no test case found in test run \(String(describing: testRunResponse))")
            return
        }
        let request = requestMgr.buildScreenshotRequest(testRunId: getTestRunId(),
                                                        testId: testCaseId,
                                                        screenshot: screenshot)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Attaches an artifact for given test case
    /// - Parameters:
    ///   - testCaseName: name of test case to attach artifact
    ///   - artifact: binary data of an artifact
    ///   - name: artifact name
    public func sendTestCaseArtifact(for testCaseName: String, with artifact: Data?, name: String) {
        guard let testCaseId = testCasesExecuted[testCaseName] else {
            print("There is no test case found in test run \(String(describing: testRunResponse))")
            return
        }
        guard let data = artifact else {
            print("There is no data to attach")
            return
        }
        
        let request = requestMgr.buildTestCaseArtifactsRequest(testRunId: getTestRunId(),
                                                               testCaseId: testCaseId,
                                                               artifact: data,
                                                               name: name)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Attaches an artifact to test run
    /// - Parameters:
    ///   - artifact: binary data of an artifact
    ///   - name: artifact name
    public func sendTestRunArtifact(artifact: Data?, name: String) {
        guard let data = artifact else {
            print("There is no data to attach")
            return
        }
        let request = requestMgr.buildTestRunArtifactsRequest(testRunId: getTestRunId(),
                                                              artifact: data,
                                                              name: name)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Attaches an artifact reference for given test case
    /// - Parameters:
    ///   - testCaseName: name of test case to attach artifact reference
    ///   - references: array with key-value pairs: name of the reference and its value
    public func sendTestCaseArtifactReference(testCaseName: String, references: [String: String]) {
        guard let testCaseId = testCasesExecuted[testCaseName] else {
            print("There is no test case found in test run \(String(describing: testRunResponse))")
            return
        }
        let request = requestMgr.buildTestCaseArtifactReferencesRequest(testRunId: getTestRunId(),
                                                                        testCaseId: testCaseId,
                                                                        references: references)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Attaches an artifact reference for test run
    /// - Parameters:
    ///   - references: array with key-value pairs: name of the reference and its value
    public func sendTestRunArtifactReferences(references: [String: String]) {
        let request = requestMgr.buildTestRunArtifactReferencesRequest(testRunId: getTestRunId(), references: references)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Attaches an array of labels to test run
    /// - Parameter labels: array with key-value pairs: name of the label and its value
    public func sendTestRunLabels(_ labels: [String: String]) {
        guard let id = testRunResponse?.id else {
            print("There is no test run id found \(String(describing: testRunResponse))")
            return
        }
        
        let request = requestMgr.buildTestRunLabelsRequest(testRunId: id, labels: labels)
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    /// Attaches an array of labels to given test case
    /// - Parameter testCaseName: test case name
    /// - Parameter labels: array with key-value pairs: name of the label and its value
    public func sendTestCaseLabels(for testCaseName: String, labels: [String: String]) {
        guard let testCaseId = testCasesExecuted[testCaseName] else {
            print("There is no test case found in test run \(String(describing: testRunResponse))")
            return
        }
        let request = requestMgr.buildTestCaseLabelsRequest(testRunId: getTestRunId(),
                                                            testCaseId: testCaseId,
                                                            labels: labels
        )
        _ = URLSession.shared.syncRequest(with: request)
    }
    
    private func getTestRunId() -> Int {
        guard let id = testRunResponse?.id else {
            print("There is no test run id or test case id found \(String(describing: testRunResponse))")
            return 0
        }
        return id
    }
    
}

// Extension of URLSesssion to execute synchronous requests
extension URLSession {
    
    /// Performs synchronous network request.
    /// - Parameter request: URLRequest object
    /// - Returns: Data, URLResponse, Error
    fileprivate func syncRequest(with request: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let dispatchGroup = DispatchGroup()
        let task = dataTask(with: request) {
            data = $0
            response = $1
            error = $2
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        task.resume()
        dispatchGroup.wait()
        
        // Check if response status code out of 200s
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            print("Unexpected response code: \(httpResponse.statusCode) for request with url: \(String(describing: request.url))")
            if let data = data,
               let err = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Data: \(err)")
            }
        }
        
        return (data, response, error)
    }
}

extension Date {
    
    /// Returns Date in ISO8601 timestamp with an offset from UTC
    /// - Parameter format: date format
    /// - Returns: String date
    func toString(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ") -> String {
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: self)
    }
    
    /// Returns current epoch unix timestamp  with millisecond-precision
    /// - Returns: String timestamp
    func currentEpochUnixTimestamp() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1_000)
        return String(timestamp)
    }
}

